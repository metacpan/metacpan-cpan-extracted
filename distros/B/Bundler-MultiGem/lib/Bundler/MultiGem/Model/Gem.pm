package Bundler::MultiGem::Model::Gem {
  use 5.006;
  use strict;
  use warnings;

  use Exporter qw(import);
  our @EXPORT = qw(gem_vname gem_vmodule_name norm_v);
  use common::sense;

  use Bundler::MultiGem::Utl::InitConfig qw(ruby_constantize);
  use File::Spec::Functions qw(catfile catdir);
  use File::Find;

=head1 NAME

Bundler::MultiGem::Model::Gem - The utility to install multiple versions of the same ruby gem

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module contains utility functions for manipulating gems

=head1 SUBROUTINES

=head2 new
  Take config as argument
=cut
  sub new {
    my $class = shift;
    my $self = { config => shift };
    bless $self, $class;
    return $self;
  }

=head2 config
  config getter
=cut
  sub config {
    my ($self, $key) = @_;
    if (!defined $key) {
      return $self->{config};
    }
    return $self->{config}->{$key}
  }

=head2 name
  name getter
=cut
  sub name {
    my $self = shift;
    return $self->config("name")
  }

=head2 source
  source getter
=cut
  sub source {
    my $self = shift;
    return $self->config("source")
  }

=head2 main_module
  main_module getter
=cut
  sub main_module {
    my $self = shift;
    return $self->config("main_module")
  }

=head2 versions
  versions getter
=cut
  sub versions {
    my $self = shift;
    return $self->config("versions")
  }

=head2 vname
  vname getter e.g. v010-foo for gem 'foo', '0.1.0'
=cut

  sub vname {
    my ($self, $v) = @_;
    if (!defined $v) {
      die "You need to provide a version to vname method";
    }
    return Bundler::MultiGem::Model::Gem::gem_vname($self->name, $v);
  }

=head2 vmodule_name
  vmodule_name getter e.g. V010::Foo for gem 'foo', '0.1.0'
=cut

  sub vmodule_name {
    my ($self, $v) = @_;
    if (!defined $v) {
      die "You need to provide a version to vmodule_name method";
    }
    return Bundler::MultiGem::Model::Gem::gem_vmodule_name($self->main_module, $v);
  }

=head1 EXPORTS

=head2 gem_vname

=cut
  sub gem_vname {
    my ($gem_name, $v) = @_;
    join('-', (norm_v($v), $gem_name));
  }

=head2 gem_vmodule_name
=cut
  sub gem_vmodule_name {
    my ($gem_module_name, $v) = @_;
    ruby_constantize(join('-', (norm_v($v), $gem_module_name)));
  }

=head2 norm_v

Normalize version name

=cut
  sub norm_v {
    my $v = shift;
    for ($v) {
      s/\.//g;
    }
    "v${v}";
  }

=head2 apply
=cut

  sub apply {
    my ($self, $dir) = @_;
    my $pkg_dir = $dir->dirs("pkg");
    my $target_dir = $dir->dirs("target");
    my @gemfile_statements = ();
    foreach my $v (@{$self->versions}) {
      my $normv = Bundler::MultiGem::Model::Gem::norm_v($v);
      my $gem_vname = $self->vname($v);
      my $gem_path = catfile( $pkg_dir, "${gem_vname}.gem" );
      my $extracted_dir = catdir( $target_dir,  $gem_vname );

      $self->fetch($gem_path, $v);
      Bundler::MultiGem::Model::Gem::unpack_gem($gem_path, $target_dir);

      $self->process_gemfile($v, $extracted_dir);

      my $lib_dir = catdir( $extracted_dir, 'lib' );
      # process main gem module
      $self->rename_main_file($v, $lib_dir);

      # Rename gem name dir in lib directory
      rename( catdir( $lib_dir, $self->name ), catdir( $lib_dir, $gem_vname )) ||
        warn catdir( $lib_dir, $self->name ) . "does not exists: $!";

      # Process all rb files in $extracted_dir, this should be refined later
      my @ruby_files = ();
      find(
        {
          wanted => sub {
              my $F = $File::Find::name;
              push @ruby_files, $F if ($F =~ /(rb|rake|Rakefile)$/)
            },
          no_chdir => 1
        },
        $extracted_dir
      );

      foreach my $f (@ruby_files) {
        $self->process_single_file($v, $f);
      }

      print $gem_vname . " completed!\n";
      push @gemfile_statements, "gem '$gem_vname', path: '$extracted_dir'";
    }
    print "Process completed.\n\n";
    print "You can add to your Gemfile something like:\n";
    foreach (@gemfile_statements) { print "$_\n"; }
  }

=head2 process_gemfile
=cut

  sub process_gemfile {
    my ($self, $v, $extracted_dir) = @_;
    my ($n, $vn, $mm, $vmn) = (
      $self->name, $self->vname($v), $self->main_module, $self->vmodule_name($v)
    );
    my $gemspec = catfile($extracted_dir, $n . ".gemspec");
    my $new_gemspec = catfile($extracted_dir, $vn . ".gemspec");

    # Process .gemspec
    open(GEMSPEC, "<${gemspec}") || die "Can't open ${gemspec}: $!";
    open(NEW_GEMSPEC, ">${new_gemspec}") || die "Can't open ${new_gemspec}: $!";

    while( my $line = <GEMSPEC> ){
      if ( $line =~ /${n}\/version/ ) { next; }
      for ($line) {
        # Replace version reference from file
        s/${mm}::VERSION/'$v'/;
        s/${n}/${vn}/g;
        s/${mm}/${vmn}/g;
      }

      print NEW_GEMSPEC $line;
    }
    close(NEW_GEMSPEC);
    close(GEMSPEC);

    unlink $gemspec || warn "Could not unlink ${gemspec}: $!";
  }

=head2 rename_main_file
=cut

  sub rename_main_file {
    my ($self, $v, $lib_dir) = @_;

    my $normv = Bundler::MultiGem::Model::Gem::norm_v($v);
    my $new_main_module = ruby_constantize($normv);

    my $main_module_file = catfile( $lib_dir, $self->name . ".rb" );
    my $new_main_module_file = catfile( $lib_dir, $self->vname($v) . ".rb" );

    if ( -e $main_module_file ) {
      open(ORIGINAL, "<${main_module_file}") ||
        die "Can't open ${main_module_file}: $!";
      my @file_content = <ORIGINAL>;
      close(ORIGINAL);

      open(NEW_FILE, ">${new_main_module_file}")  ||
        die "Can't open ${new_main_module_file}: $!";
      print NEW_FILE "module ${new_main_module}; end\n";
      foreach my $line (@file_content) { print NEW_FILE $line; }
      close(NEW_FILE);

      unlink $main_module_file;
    }
  }

=head2 process_single_file
=cut
  sub process_single_file {
    my ($self, $v, $f) = @_;

    my ($n, $vn, $mm, $vmn) = (
      $self->name, $self->vname($v), $self->main_module, $self->vmodule_name($v)
    );
    my $bkp = $f . ".bak";
    rename($f, $bkp);
    open(I, "<$bkp");
    open(O, ">$f");
    while(my $line = <I>) {
      for ($line) {
        s/${n}/${vn}/g;
        s/${mm}/${vmn}/g;
      }
      print O $line;
    }
    close(O);
    close(I);
    unlink $bkp;
  }

=head2 unpack_gem
=cut

  sub unpack_gem {
    my ($gem_filepath, $target_dir) = @_;
    system("gem unpack ${gem_filepath} --target ${target_dir}");
  }

=head2 fetch_gem
=cut

  sub fetch {
    my ( $self, $fp, $gv ) = (@_);
    if (! -f $fp ) {
      my $cmd = "gem fetch " . $self->name . " --version " . $gv .
                " --source " . $self->source;
      system("$cmd");
      rename( $self->name . "-$gv" . ".gem", $fp );
    }
  }
};
1;