package App::Math::Tutor::Role::PowerExercise;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Role::PowerExercise - role for exercises in power mathematics

=cut

use Moo::Role;
use MooX::Options;

with "App::Math::Tutor::Role::Exercise", "App::Math::Tutor::Role::Power";

our $VERSION = '0.005';

=head1 ATTRIBUTES

=head2 format

Specifies format of basis^exponent

=cut

option format => (
    is       => "ro",
    doc      => "specifies format of basis^exponent",
    long_doc => "Allow specifying the format of the basis^exponent "
      . "whereby any digit is typed with 'n' as placeholder:\n\n"
      . "\t--format 5nnn^nn\n\n"
      . "creates power between 5999^99 and 0002^02.\n\n"
      . "Default: 20^10",
    isa => sub {
        defined( $_[0] )
          and !ref $_[0]
          and $_[0] !~ m,^\d?n+(?:\^\d?n+)?$,
          and die("Invalid format");
    },
    coerce => sub {
        defined( $_[0] )
          or return [ 20, 10 ];
        ref $_[0] eq "ARRAY" and return $_[0];

        my ( $fmta, $fmtb ) = ( $_[0] =~ m,^(\d?n+)(?:\^(\d?n+))?$, );
        defined $fmtb or $fmtb = $fmta;
        my $starta = "1";
        my $startb = "1";
        $fmta =~ s/^(\d)(.*)/$2/ and $starta = $1;
        $fmtb =~ s/^(\d)(.*)/$2/ and $startb = $1;
        my $maxa = $starta . "0" x length($fmta);
        my $maxb = $startb . "0" x length($fmtb);
        [ $maxa, $maxb ];
    },
    default => sub { [ 20, 10 ] },
    format  => "s",
    short   => "f",
);

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
