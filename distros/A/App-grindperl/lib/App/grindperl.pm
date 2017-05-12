use v5.10.0;
use strict;
use warnings;

package App::grindperl;
our $VERSION = '0.004';

use autodie;
use Getopt::Lucid ':all';
use Path::Class;
use File::Spec;
use Carp qw/carp croak/;
use File::Copy qw/copy/;
use File::HomeDir 0.98;
use namespace::autoclean;

sub new {
  my $class = shift;

  my $self = bless {}, $class;

  if ( -r $self->config_file ) {
    unshift @ARGV, $self->read_config_file;
  }

  my $opt = Getopt::Lucid->getopt([
    Param("jobs|j")->default(9),
    Param("testjobs|t")->default(9),
    Param("output|o"),
    Param("install_root")->default(File::Spec->tmpdir),
    Param("prefix"),
    Switch("debugging")->default(1),
    Switch("threads")->default(1),
    Switch("32"),
    Switch("porting|p"),
    Switch("install"),
    Switch("config"),
    Switch("cache"),
    Switch("man"),
    Switch("edit"),
    Switch("verbose|v"),
    Keypair("additions|A"),
    Keypair("define|D"),
    List("undefine|U"),
  ]);

  $self->{opt} = $opt;
  $self->{is_git} = -d '.git';

  return $self;
}

sub opt { return $_[0]->{opt} }

sub is_git { return $_[0]->{is_git} }

sub logfile { return $_[0]->opt->get_output };

sub vlog {
  my ($self, @msg) = @_;
  return unless $self->opt->get_verbose;
  say for map { (my $s = $_) =~ s/\n$//; $s } @msg;
}

sub prefix {
  my $self = shift;
  my $prefix = $self->opt->get_prefix;
  return $prefix if defined $prefix && length $prefix;

  my $root = $self->opt->get_install_root;

  if ( $self->is_git ) {
    my $branch = qx/git symbolic-ref HEAD/;
    if ( $? ) {
      # HEAD not a symbolic ref?
      $branch = "fromgit";
    }
    else {
      chomp $branch;
      $branch =~ s{refs/heads/}{};
      $branch =~ s{/}{-}g;
    }
    my $describe = qx/git describe/;
    if ( $? ) {
      # can't describe?
      $describe = 'unknown-commit';
    }
    chomp $describe;
    return dir($root)->subdir("$branch-$describe");
  }
  else {
    my $perldir = dir()->absolute->basename;
    return dir($root)->subdir("$perldir-" . time());
  }
}

sub configure_args {
  my ($self) = @_;
  my %defines = $self->opt->get_define;
  my @undefines = $self->opt->get_undefine;
  my %additions = $self->opt->get_additions;
  my @args = qw/-des -Dusedevel -Uversiononly/;
  push @args, "-Dusethreads" if $self->opt->get_threads;
  push @args, "-DDEBUGGING" if $self->opt->get_debugging;
  push @args, "-Accflags=-m32", "-Alddlflags=-m32", "-Aldflags=-m32",
    "-Uuse64bitint", "-Uuse64bitall", "-Uusemorebits"
    if $self->opt->get_32;
  push @args, "-r" if $self->opt->get_cache;
  if ( ! $self->opt->get_man ) {
    push @args, qw/-Dman1dir=none -Dman3dir=none/;
  }
  push @args, map { "-D$_=$defines{$_}" } keys %defines;
  push @args, map { "-U$_" } @undefines;
  push @args, map { "-A$_=$additions{$_}" } keys %additions;
  push @args, "-Dprefix=" . $self->prefix;
  return @args;
}

sub cache_dir {
  my ($self) = @_;
  return dir(File::HomeDir->my_dist_data('App-grindperl', {create=>1}))->stringify;
}

sub cache_file {
  my ($self,$file) = @_;
  croak "No filename given to cache_file()"
    unless defined $file && length $file;
  return file( $self->cache_dir, $file )->stringify;
}

sub config_file {
  my ($self) = @_;
  my $config_dir = dir(File::HomeDir->my_dist_config('App-grindperl', {create=>1}));
  return $config_dir->file("grindperl.conf");
}

sub read_config_file {
  my ($self) = @_;
  open my $fh, "<", $self->config_file;
  my @args;
  while ( my $line = <$fh> ) {
    chomp $line;
    push @args, split " ", $line, 2;
  }
  return @args;
}

sub do_cmd {
  my ($self, $cmd, @args) = @_;

  my $cmdline = join( q{ }, $cmd, @args);
  if ( $self->logfile ) {
    $cmdline .= " >" . $self->logfile . " 2>&1";
  }
  $self->vlog("Running '$cmdline'");
  system($cmdline);
  return $? == 0;
}

sub verify_dir {
  my ($self) = @_;
  my $prefix = dir($self->prefix);
  return -w $prefix->parent;
}

sub configure {
  my ($self) = @_;
  croak("Executable Configure program not found") unless -x "Configure";

  # used cached files
  for my $f ( qw/config.sh Policy.sh/ ) {
    next unless -f $self->cache_file($f);
    if ( $self->opt->get_cache ) {
      copy( $self->cache_file($f), $f );
      if ( -f $f ) {
        $self->vlog("Copied $f from cache");
      }
      else {
        $self->vlog("Faild to copy $f from cache");
      }
    }
    else {
      unlink $self->cache_file($f);
    }
  }

  $self->do_cmd( "./Configure", $self->configure_args )
    or croak("Configure failed!");

  # save files back into cache if updated
  dir( $self->cache_dir )->mkpath;
  for my $f ( qw/config.sh Policy.sh/ ) {
    copy( $f, $self->cache_file($f) )
      if (! -f $self->cache_file($f)) || (-M $f > -M $self->cache_file($f));
  }

  return 1;
}

sub run {
  my ($self) = @_;

  if ( $self->opt->get_edit ) {
    my $cf_file = $self->config_file;
    if ( $ENV{EDITOR} ) {
      system( $ENV{EDITOR}, $cf_file )
          and die "Error editing config file: $!\n";
    }
    else {
      say "No EDITOR set. Edit $cf_file manually.";
    }
    exit 0;
  }

  die "This doesn't look like a perl source directory.\n"
    unless -f "perl.c";

  my $prefix = $self->prefix;
  die "Can't install to $prefix\: parent directory is not writeable\n"
    unless -w dir($prefix)->parent;

  if ( $self->is_git ) {
    $self->do_cmd("git clean -dxf")
  }
  else {
    $self->do_cmd("make distclean") if -f 'Makefile';
  }

  $self->configure;

  exit 0 if $self->opt->get_config; # config only

  my $test_jobs = $self->opt->get_testjobs;
  my $jobs = $self->opt->get_jobs;

  if ( $test_jobs ) {
    $ENV{TEST_JOBS} = $test_jobs if $test_jobs > 1;

    if ( $self->opt->get_porting ) {
      $self->vlog("Running 'make test_porting' with $test_jobs jobs");
      $self->do_cmd("make -j $jobs test_porting")
        or croak ("make test_porting failed");
    }
    elsif ( grep { /test_harness/ } do { local(@ARGV,$/) = "Makefile"; <>} ) {
      $self->vlog("Running 'make test_harness' with $test_jobs jobs");
      $self->do_cmd("make -j $jobs test_harness")
          or croak ("make test_harness failed");
    }
    else {
      $self->vlog("Running 'make test' with $test_jobs jobs");
      $self->do_cmd("make -j $jobs test")
          or croak ("make test failed");
    }
  }
  else {
    $self->vlog("Running 'make test_prep' with $test_jobs jobs");
    $self->do_cmd("make -j $jobs test_prep")
      or croak("make test_prep failed!");
  }

  if ( $self->opt->get_install ) {
    $self->vlog("Running 'make install'");
    $self->do_cmd("make install")
      or croak("make install failed!");
  }

  return 0; # usually passed to exit
}

1;

# ABSTRACT:  Guts of the grindperl tool


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

App::grindperl - Guts of the grindperl tool

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use App::grindperl;
  my $app = App::grindperl->new;
  exit $app->run;

=head1 DESCRIPTION

This module contains the guts of the L<grindperl> program.

=for Pod::Coverage new
opt
is_git
logfile
vlog
default_args
prefix
configure_args
cache_dir
cache_file
config_file
read_config_file
do_cmd
verify_dir
configure
run

=head1 SEE ALSO

L<grindperl>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/App-grindperl/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/App-grindperl>

  git clone https://github.com/dagolden/App-grindperl.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=for stopwords David Golden Sawyer X

=over 4

=item *

David Golden <xdg@xdg.me>

=item *

Sawyer X <xsawyerx@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
