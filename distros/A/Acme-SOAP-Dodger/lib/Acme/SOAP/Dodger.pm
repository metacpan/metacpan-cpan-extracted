package Acme::SOAP::Dodger;

=head1 NAME

  Acme::SOAP::Dodger - be a hippy

=head1 SYNOPSIS

  use Acme::SOAP::Dodger;

=head1 DESCRIPTION

I hate SOAP. You hate SOAP. So don't use SOAP.

=head1 Why, dear God, why?

I was having a discussion on why SOAP sucked. And it lent itself to amusing
jokes and japes. Oh, what witty people programmers are, eh? This was
constructed in a few minutes. No doubt there are cleverer ways of doing it. I
don't care. I am too busy being a hater.

=cut

use strict;
use warnings;

our $VERSION = 0.002;

use Symbol qw/delete_package/;

sub import {
  for my $mod (keys %INC) {
    do {
      delete $INC{$mod};
      $mod =~ s/\.pm$//; $mod =~ s/\//::/g;
      delete_package($mod);
    } if $mod =~ m/^SOAP/;
  }
}

=head1 AUTHOR

Stray Taoist E<lt>F<mwk@strayLALAtoaster.co.uk>E<gt>

Take out the Tellytubby if you particularly feel inclined to mail me.

=head1 COPYRIGHT

Copyright (c) 2007 StrayTaoist

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=head1 STUFF

 o things

=head1 THINGS

 o stuff

=cut

return qw/Get a haircut son you look like a godamned girl/;
