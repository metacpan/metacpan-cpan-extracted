package Bundler::MultiGem::Model::Gem;

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

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module contains utility functions for manipulating gems

=head1 SUBROUTINES

=head2 new

Takes an hash reference parameter. You should provide:
  * C<name>: string, gem name in repository
  * C<main_module>: string, gem main module name
  * C<source>: string, e.g. C<"https://rubygems.org">
  * C<versions>: array ref of strings, e.g. C<[qw( 0.0.5 0.1.0 )]>

    my $config = {
      name => "jsonschema_serializer",
      main_module => "JsonschemaSerializer",
      source => "https://rubygems.org",
      versions => [qw( 0.0.5 0.1.0 )]
    };
    my $gem = Bundler::MultiGem::Model::Gem->new($config);

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

C<name> getter

    $gem->name; # "jsonschema_serializer"

=cut
sub name {
  my $self = shift;
  return $self->config("name")
}

=head2 source

C<source> getter

    $gem->source; # "https://rubygems.org"

=cut
sub source {
  my $self = shift;
  return $self->config("source")
}

=head2 main_module

C<main_module> getter

    $gem->main_module; # "JsonschemaSerializer"

=cut
sub main_module {
  my $self = shift;
  return $self->config("main_module")
}

=head2 versions


C<versions> getter

    $gem->versions; # [qw( 0.0.5 0.1.0 )]

=cut
sub versions {
  my $self = shift;
  return $self->config("versions")
}

=head2 vname

C<vname> getter: combine gem name and version and format it
  * C<v>: string, a gem version reference

    $gem->name; # "jsonschema_serializer"
    my $v = "0.0.5";
    $gem->vname($v); # "v005-jsonschema_serializer"


=cut

sub vname {
  my ($self, $v) = @_;
  if (!defined $v) {
    die "You need to provide a version to vname method";
  }
  return Bundler::MultiGem::Model::Gem::gem_vname($self->name, $v);
}

=head2 vmodule_name

C<vmodule_name> getter: combine gem name and version and format it
  * C<v>: string, a gem version reference

    $gem->main_module; # "JsonschemaSerializer"
    my $v = "0.0.5";
    $gem->vmodule_name($v); # "V005::JsonschemaSerializer"

=cut

sub vmodule_name {
  my ($self, $v) = @_;
  if (!defined $v) {
    die "You need to provide a version to vmodule_name method";
  }
  return Bundler::MultiGem::Model::Gem::gem_vmodule_name($self->main_module, $v);
}

=head2 apply

This function apply all the transformation to the gem versions to be reused in the same C<Gemfile>:
  C<dir>, a C<Bundler::MultiGem::Model::Directories> instance

For each gem version it will:
  * fetch the gem version
  * extract it into a target directory
  * C<process_gemfile>
  * C<rename_main_file>
  * rename the lib directory including the version name
  * for each C<rb>, C<rake> and C<Rakefile> apply C<process_single_file>

Caveats:
  * if you are renaming C<foo-bar> to C<V123::Foo::Bar>, also partial matches will be renamed: e.g. C<foo-bar_baz>
  * this is intended for benchmarking simple gems, it may break with very complex gems
  * the use case leading this development was benchmarking serialization gems performance
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

    # Process all ruby files
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

Manipulates original gemfile as follows:
  * rename C<foo.gemspec> for v C<0.1.0> into C<v010-foo.gemspec>
  * remove line importing gem version (usually C<require_relative 'lib/foo/version'>)
  * replace main_module version with the actual version (C<Foo::VERSION> with C<'0.1.0'>)
  * replace gem name reference with gem vname (C<foo> with C<v010-foo>)
  * replace gem main_module reference with gem vmodule_name (C<Foo> with C<V010::Foo>)
  * unlink the original C<foo.gemspec>

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

Manipulates original gemfile as follows:
  * rename C<lib/foo.rb> for v C<0.1.0> into C<lib/v010-foo.rb>
  * add on top of C<lib/v010-foo.rb>: C<module V010; end> for namespacing
  * copy the rest of original below

This step allows to add a namespace with the gem version (a kind of shading).
All the other replacement are done with other rb, rake and Rakfile files.

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

Manipulates each file as follows:
  * create a backup of the original file C<.bak>
  * replace gem name reference with gem vname (C<foo> with C<v010-foo>)
  * replace gem main_module reference with gem vmodule_name (C<Foo> with C<V010::Foo>)
  * unlink the backup C<.bak>

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

=head2 fetch

This is an alias of the system command C<gem fetch>

    my $gem->name; # "foo"
    my $fp = "pkg/v010-foo.gem"
    my $gv = "0.1.0";
    $gem->fetch($fp, $gv); # if $fp found, do nothing, else fetch gem version and rename it

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

=head1 EXPORTS

=head2 gem_vname

Reusable function to combine and format gem name and version

    use Bundler::MultiGem::Model::Gem qw(gem_vname);
    gem_vname("foo", "0.1.0"); # v010-foo
    gem_vname("foo_bar", "0.1.0"); # v010-foo_bar
    gem_vname("foo-bar", "0.1.0"); # v010-foo-bar

=cut

sub gem_vname {
  my ($gem_name, $v) = @_;
  join('-', (norm_v($v), $gem_name));
}

=head2 gem_vmodule_name

Reusable function to combine and format gem main module and version

    use Bundler::MultiGem::Model::Gem qw(gem_vmodule_name);
    gem_vname("Foo", "0.1.0"); # V010::Foo
    gem_vname("FooBar", "0.1.0"); # V010::FooBar
    gem_vname("Foo::Bar", "0.1.0"); # V010::Foo::Bar

=cut
sub gem_vmodule_name {
  my ($gem_module_name, $v) = @_;
  ruby_constantize(join('-', (norm_v($v), $gem_module_name)));
}

=head2 norm_v

Utility function to normalize version name

    use Bundler::MultiGem::Model::Gem qw(norm_v);
    norm_v("123"); #v123
    norm_v("1.23"); #v123
    norm_v("12.3"); #v123
    norm_v("1.2.3"); #v123
=cut

sub norm_v {
  my $v = shift;
  for ($v) {
    s/\.//g;
  }
  "v${v}";
}

=head2 unpack_gem

This is an alias of the system command C<gem unpack>

=cut

sub unpack_gem {
  my ($gem_filepath, $target_dir) = @_;
  system("gem unpack ${gem_filepath} --target ${target_dir}");
}

=head1 AUTHOR

Mauro Berlanda, C<< <kupta at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/mberlanda/Bundler-MultiGem/issues>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bundler::MultiGem::Directories


You can also look for information at:

=over 2

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bundler-MultiGem>

=item * Github Repository

L<https://github.com/mberlanda/Bundler-MultiGem>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Mauro Berlanda.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
