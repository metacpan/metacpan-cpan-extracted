package App::VW::Start;
use strict;
use warnings;
use base 'App::VW::Command';

sub run {
  my ($self) = @_;
  system("/etc/init.d/vw start");
}

1;

=head1 NAME

App::VW::Start - start all configured Squatting apps

=head1 SYNOPSIS

Usage:

  vw start

=head1 DESCRIPTION

This is a wrapper around:

  /etc/init.d/vw start

=cut
