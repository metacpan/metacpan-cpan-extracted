package App::Sybil;

use strict;
use warnings;
use v5.12;

our $VERSION = '0.3';

use App::Cmd::Setup -app;

use Capture::Tiny ':all';
use File::Slurp;
use File::Spec;

sub _get_project_from_path {
  my ($self) = @_;

  my @dirs = File::Spec->splitdir(File::Spec->rel2abs(File::Spec->curdir));
  return $dirs[-1];
}

sub project {
  my ($self) = @_;

  $self->{project} ||= $self->_get_project_from_path();
  return $self->{project};
}

sub _get_version_from_git {
  my ($self) = @_;

  my $version = capture_stdout {
    system 'git', 'describe', '--dirty', '--tags';
  };
  chomp $version;

  return $version;
}

sub version {
  my ($self) = @_;

  $self->{version} ||= $self->_get_version_from_git();
  return $self->{version};
}

sub targets {
  my ($self) = @_;

  return qw(linux win32 win64);
}

sub output_file {
  my ($self, $version, $target) = @_;

  return $self->project . "-$version-$target." . ($target =~ /^win/ ? 'zip' : 'tgz');
}

sub has_build {
  my ($self, $version) = @_;

  foreach my $target ($self->targets) {
    my $file = $self->output_file($version, $target);
    unless (-e $file) {
      say STDERR "Missing build artifact $file";
      return undef;
    }
  }

  return 1;
}

sub local_config { return '.sybilrc'; }
sub global_config { return File::Spec->catfile($ENV{HOME}, '.sybilrc'); }

sub _write_token {
  my ($self, $token) = @_;

  write_file($self->global_config, $token);
}

sub _read_token {
  my ($self) = @_;

  if (-f $self->local_config) {
    return read_file($self->local_config);
  } elsif (-f $self->global_config) {
    return read_file($self->global_config);
  }

  return undef;
}

sub github_token {
  my ($self) = @_;

  $self->{token} ||= $self->_read_token();
  return $self->{token};
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Sybil - Multi platform build and release manager

=head1 SYNOPSIS

    $ sybil release
    Building linux version v1.3
    Building windows version v1.3
    $ sybil publish
    Publishing version v1.3 to github

=head1 DESCRIPTION

App::Sybil is a tool for managing and publishing release builds of your
software.  It is opinionated but somewhat configurable.

=head1 AUTHOR

Alan Berndt <alan@eatabrick.org>

=head1 COPYRIGHT

Copyright 2017 Alan Berndt

=head1 LICENSE


=head1 SEE ALSO
