package App::Math::Tutor::Role::PolyExercise;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Role::PolyExercise - role for for exercises with polynom

=cut

use Moo::Role;
use MooX::Options;

with "App::Math::Tutor::Role::Exercise", "App::Math::Tutor::Role::Poly";

use Scalar::Util qw/looks_like_number/;

our $VERSION = '0.005';

=head1 ATTRIBUTES

=head2 format

Specifies format of factor per term

=cut

option format => (
    is       => "ro",
    doc      => "specifies format of natural number as factor per term",
    long_doc => "Allow specifying the format of the natural number "
      . "whereby any digit is typed with 'n' as placeholder:\n\n"
      . "\t--format 5nnn\n\n"
      . "creates natural numbers from -5999 .. 5999.\n\n"
      . "Default: 100",
    isa => sub {
        defined( $_[0] )
          and !looks_like_number( $_[0] )
          and $_[0] !~ m,^\d?n+?$,
          and die("Invalid format");
    },
    coerce => sub {
        defined( $_[0] ) or return 100;
        looks_like_number( $_[0] ) and int( $_[0] ) == $_[0] and return $_[0];

        my ($fmtv) = ( $_[0] =~ m,^(\d?n+)?$, );
        my $startv = "1";
        $fmtv =~ s/^(\d)(.*)/$2/ and $startv = $1;
        my $maxv = $startv . "0" x length($fmtv);
        $maxv;
    },
    default => sub { 100 },
    format  => "s",
    short   => "f",
);

=head2 max_power

Specifies format of exponent

=cut

option max_power => (
    is       => "ro",
    doc      => "specifies the highest exponent",
    long_doc => "Allow specifying the format of the polynom " . "by using the higest exponent.\n\n" . "Default: 2",
    isa      => sub {
        defined( $_[0] )
          and !looks_like_number( $_[0] )
          and die("Invalid exponent");
        int( $_[0] ) == $_[0]
          or die("Invalid exponent");
    },
    default => sub { 2 },
    format  => "i",
    short   => "e",
);

=head2 probability

Specifies probability per term in %

=cut

option probability => (
    is       => "ro",
    doc      => "specifies probability per term",
    long_doc => "Allow specifying the probability of each term of the polynom\n\n" . "Default: 80",
    isa      => sub {
        defined( $_[0] )
          and !looks_like_number( $_[0] )
          and die("Invalid probability");
        $_[0] <= 0
          and $_[0] > 100
          and die("Invalid probability");
    },
    default => sub { 95 },
    format  => "f",
    short   => "p",
);

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
