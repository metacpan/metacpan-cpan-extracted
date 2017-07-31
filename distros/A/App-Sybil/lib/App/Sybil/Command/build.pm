package App::Sybil::Command::build;

use strict;
use warnings;
use v5.12;

use App::Sybil -command;

use File::Copy;

sub abstract { 'Build your software' }

sub description { 'Does a release build of your software package.' }

sub _build {
  my ($self, $target, @opts) = @_;

  system 'bazel', 'build', '-c', 'opt', ":$target", @opts;

  if ($? == -1) {
    say STDERR 'Build failed';
    return undef;
  }

  return 1;
}

sub _linux_build {
  my ($self) = @_;

  my $project = $self->app->project;
  my $version = $self->app->version;

  # TODO autodetect build rule
  my $target = "$project-linux";
  $self->_build($target) or return;

  # TODO improve result name detection
  my $file = "$project-$version-linux.tgz";
  unless (copy("bazel-bin/$target.tgz", $file)) {
    say STDERR "Copy bazel-bin/$target.tgz to $file failed: $!";
    return;
  }

  say STDERR 'Build complete';
}

sub _windows_build {
  my ($self, $cpu) = @_;

  my $project = $self->app->project;
  my $version = $self->app->version;

  my @options =
    ('--crosstool_top', '@mxebzl//tools/windows:toolchain', '--cpu', $cpu,);

  # TODO autodetect build rule
  my $target = "$project-windows";
  $self->_build($target, @options) or return;

  # TODO improve result name detection
  my $file = "$project-$version-$cpu.zip";
  unless (copy("bazel-bin/$target.zip", $file)) {
    say STDERR "Copy bazel-bin/$target.zip to $file failed: $!";
    return;
  }

  say STDERR 'Build complete';
}

sub _osx_build {
  my ($self) = @_;

  say STDERR 'OSX builds not yet supported';
}

sub execute {
  my ($self, $opt, $args) = @_;

  $self->_linux_build();
  $self->_windows_build('win32');
  $self->_windows_build('win64');
  $self->_osx_build();
}

1;
