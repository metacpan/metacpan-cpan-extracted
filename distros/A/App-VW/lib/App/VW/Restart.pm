package App::VW::Restart;
use strict;
use warnings;
use base 'App::VW::Command';

sub run {
  my ($self) = @_;
  system("/etc/init.d/vw restart");
}

1;

=head1 NAME

App::VW::Restart - restart all configured Squatting apps

=head1 SYNOPSIS

Usage:

  vw restart

=head1 DESCRIPTION

This is a wrapper around:

  /etc/init.d/vw restart

=cut
