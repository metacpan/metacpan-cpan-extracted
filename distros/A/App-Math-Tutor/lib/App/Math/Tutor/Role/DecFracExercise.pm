package App::Math::Tutor::Role::DecFracExercise;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Role::DecFracExercise - role for exercises in decimal fraction

=cut

use Moo::Role;
use MooX::Options;

with "App::Math::Tutor::Role::Exercise", "App::Math::Tutor::Role::DecFrac";

use Scalar::Util qw(looks_like_number);

our $VERSION = '0.005';

sub _lt { $_[0] < $_[1]; }
sub _le { $_[0] <= $_[1]; }
sub _gt { $_[0] > $_[1]; }
sub _ge { $_[0] >= $_[1]; }
sub _ok { 1; }

=head1 ATTRIBUTES

=head2 range

Specifies range of resulting numbers ([m..n] or [m..[n or m]..n] ...)

=cut

option range => (
    is       => "ro",
    doc      => "Specifies range of results",
    long_doc => "Specifies range of fraction value using a lower and an upper limit:\n\n"
      . "\t--range [m..n] -- includes value of m and n in range\n\n"
      . "\t--range [m..[n -- includes value of m in range, but exlude n\n\n"
      . "\t--range m]..n] -- excludes value of m from rangem but include n\n\n",
    isa => sub {
        defined( $_[0] )
          and !ref $_[0]
          and $_[0] !~ m/^(\[?)((?:\d?\.)?\d+)(\]?)\.\.(\[?)((?:\d?\.)?\d+)(\]?)$/
          and die("Invalid range");
    },
    coerce => sub {
        defined( $_[0] )
          or return [ 0, \&_lt, undef, \&_ok ];

        ref $_[0] eq "ARRAY" and return $_[0];

        my ( $fmtmin, $fmtmax ) = (
            $_[0] =~ m/^( (?:\[(?:\d+\.?\d*)|(?:\.?\d+))
			  |
			  (?:(?:\d+\.?\d*)|(?:\.?\d+)\])
		        )
		        (?:\.\.
			  (
			      (?:\[(?:\d+\.?\d*)|(?:\.?\d+))
			      |
			      (?:(?:\d+\.?\d*)|(?:\.?\d+)\])
			  )
		        )?$/x
        );
        my ( $minr, $minc, $maxr, $maxc );

        $fmtmin =~ s/^\[// and $minc = \&_le;
        $fmtmin =~ s/\]$// and $minc = \&_lt;
        defined $minc or $minc = \&_lt;
        $minr = $fmtmin;

        if ( defined($fmtmax) )
        {
            $fmtmax =~ s/^\[// and $maxc = \&_gt;
            $fmtmax =~ s/\]$// and $maxc = \&_ge;
            defined $maxc or $maxc = \&_ge;
            $maxr = $fmtmax;
        }
        else
        {
            $maxc = \&_ok;
        }

        [ $minr, $minc, $maxr, $maxc ];
    },
    default => sub { [ 0, \&_lt, undef, \&_ok ]; },
    format  => "s",
    short   => "r",
);

=head2 digits

Specifies number of decimal digits (after decimal point)

=cut

option digits => (
    is       => "ro",
    doc      => "Specified number of decimal digits (after decimal point)",
    long_doc => "Specify count of decimal digits after decimal point (limit value using range)",
    isa      => sub {
        defined( $_[0] )
          and looks_like_number( $_[0] )
          and $_[0] != int( $_[0] )
          and die("Digits must be natural");
        defined( $_[0] )
          and ( $_[0] < 2 or $_[0] > 13 )
          and die("Digits must be between 2 and 13");
    },
    coerce => sub {
        int( $_[0] );
    },
    default => sub { 5; },
    format  => "s",
    short   => "g",
);

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
