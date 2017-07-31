package App::Sybil::Command::clean;

use strict;
use warnings;
use v5.12;

use App::Sybil -command;

use File::Glob 'bsd_glob';

sub abstract { 'Clean up any builds in the current directory.' }

sub execute {
  my ($self, $opt, $args) = @_;

  my @files = bsd_glob($self->app->project . '-*.{zip,tgz}');
  my $count = scalar @files;
  say STDERR "Found $count release files to clean up.";
  say STDERR "Deleting $_" for @files;
  unlink @files;
}

1;
