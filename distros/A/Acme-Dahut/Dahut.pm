
###
# Acme::Dahut - a module for the higher circles
# Robin Berjon <robin@knowscape.com>
# 30/11/2001 - v0.42
###

package Acme::Dahut;
use strict;

use vars qw($VERSION);
$VERSION = '0.42';


#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, DAAAAAAHUUUUUUT !!!!!! ,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

#-------------------------------------------------------------------#
# use a dahut
#-------------------------------------------------------------------#
sub import {
    shift;
    if (@_) {
        my $side = shift;
        if (lc($side) eq ':right') {
#line 65535
            die "Cannot coerce LVALUE to GLOB in entersub";
        }
        elsif (lc($side) eq ':left') {
            warn "\n\n\n\t\DAAAAAAHUUUUUUUUT !!!!!\n\n\n";
        }
    }
}
#-------------------------------------------------------------------#

#-------------------------------------------------------------------#
# make a dahut
#-------------------------------------------------------------------#
sub new {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $dahut = \substr($class, 6, 5);
    return bless $dahut, $class;
}
#-------------------------------------------------------------------#

#-------------------------------------------------------------------#
# call a dahut
#-------------------------------------------------------------------#
sub call {
#line 65535
    die "Can't coerce DAHUT to RVALUE in slopysub" unless int(rand 10) >= 9;
}
#-------------------------------------------------------------------#


1;
#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Documentation `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

=pod

=head1 NAME

Acme::Dahut - A module for the Higher Circles

=head1 SYNOPSIS

  use Acme::Dahut qw(:right); # dies, this is a left dahut
  use Acme::Dahut qw(:left);

  my $dahut = Acme::Dahut->new;
  $dahut->call;

=head1 DESCRIPTION

Acme::Dahut is the produce of the deranged imaginations of the #axkit
Higher Circles.

As far as I know, it's the only module the constructor of which returns
a blessed LVALUE. But this is to be expected, as it powerfully captures
the business logic of a Left Dahut.

=head1 METHODS

=over 4

=item * new

Makes a new dahut.

=item * call

Call the dahut. If you're good you'll get to catch it.

=back

=head1 DAHUTOLOGY

One of the main centers of dahut-lore is #axkit, on irc.rhizomatic.net
(or london.rhizomatic.net for us euros).

You may find an occasional mention of dahut-knowledge from
http://use.perl.org/~darobin/journal/, but just as well you may not.
Such is the way of the dahut.

The current ultimate reference is http://berjon.com/dahut.txt .

A collection of Zen Dahut Poetry by Kip Hampton and Barrie Slaymaker
is confidently expected any decade now.

=head1 AUTHOR

Robin Berjon, robin@knowscape.com; with folks from the #axkit conspiracy
including but not limited to ubu, c, briac, and acme. Of course, this is
without mentionning the names of those that built the Dahut. Or maybe it
is. Or maybe just some. It depends on the Cycle.

Thanks also to pepl, barries, baud, phish108, and others which I probably
forget (also unrelated folks).

=head1 COPYRIGHT

Copyright (c) 2001 Robin Berjon. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

Acme::*

=cut
