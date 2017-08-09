package App::Sybil::Command::build;

use strict;
use warnings;
use v5.12;

use App::Sybil -command;

sub abstract { 'Build your software' }

sub description { 'Does a release build of your software package.' }

sub execute {
  my ($self, $opt, $args) = @_;

  my $project = $self->app->project;
  my $version = $self->app->version;

  say STDERR "Building version $version";

  $self->app->build_all_targets($project, $version);
}

1;
