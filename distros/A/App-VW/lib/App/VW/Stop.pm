package App::VW::Stop;
use strict;
use warnings;
use base 'App::VW::Command';

sub run {
  my ($self) = @_;
  system("/etc/init.d/vw stop");
}

1;

=head1 NAME

App::VW::Stop - stop all configured Squatting apps

=head1 SYNOPSIS

Usage:

  vw stop

=head1 DESCRIPTION

This is a wrapper around:

  /etc/init.d/vw stop

=cut
