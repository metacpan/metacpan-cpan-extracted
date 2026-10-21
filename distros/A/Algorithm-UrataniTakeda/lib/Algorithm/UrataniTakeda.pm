# SPDX-FileCopyrightText: 2026 Robert Rothenberg <perl@rhizomnic.com>
# SPDX-License-Identifier: Artistic-2.0

use v5.26;
use warnings;

use Object::Pad 0.59;

# ABSTRACT: an implementation of the Uratani-Takeda string searching algorithm

package Algorithm::UrataniTakeda;

our $VERSION = 'v0.1.7';

use Carp ();
use List::Util ();


class Algorithm::UrataniTakeda {

    field $states = [];
    field $fails  = [];
    field $alpha  = {};   # code points occurring in any pattern
    field $ends   = [];
    field $left   = [];
    field $depth  = [];
    field $phi    = [];
    field $min    = -1;
    field $shift1 = [];
    field $shift2 = [];

    method $enter($pattern) {

        use integer;

        my @string = unpack( "U*", $pattern );
        my $i = $#string;

        $alpha->{$_} //= 1 for @string;

        $min = $i if $min < 0 || $min > $i;

        my $n = 0;

        while ($i >= 0) {

            $states->[$n] //= {};

            if ( exists $states->[$n]{ $string[$i] } ) {
                $n = $states->[$n]{ $string[$i] };
            }
            else {
                $n = $states->[$n]{ $string[$i] } = 1 + $#$states;
                $depth->[$n] = $#string - $i + 1;
            }

            $i--;
        }

        $states->[$n] //= {};
        $ends->[$n] = $pattern;
        push $left->@*, $n;
    }

    method $build_phi {

        use integer;

        my @q = values $states->[0]->%*;
        $phi =  [ (0) x (1 + $#$states) ];

        while (@q) {
            my $r = shift @q;
            for my $c ( keys $states->[$r]->%* ) {
                push @q, my $s = $states->[$r]{$c};
                my $z = $phi->[$r];
                while ( !exists $states->[$z]{$c} ) {
                    $z = $phi->[$z] or last;
                }
                $phi->[$s] = $states->[$z]{$c} // 0;
            }
        }
    }

    method $build_shift1 {

        use integer;

        $shift1 = [ map { {} } 0.. $#$states ];

        my @q = grep { $_ > 0 } values $states->[0]->%*;

        while (@q) {
            my $r = shift @q;

            for my $c ( keys $states->[$r]->%* ) {
                push @q, my $s = $states->[$r]{$c};
                my $z = $phi->[$r];

                while ( !exists $states->[$z]{$c}) {

                    my $a = $shift1->[$z]{$c};
                    my $b = $depth->[$r];
                    $shift1->[$z]{$c} = $b unless $a && $a < $b;

                    $z = $phi->[$z] or last;
                }

                if ( ! exists $states->[$z]{$c} ) {

                    my $a = $shift1->[$z]{$c};
                    my $b = $depth->[$r];
                    $shift1->[$z]{$c} = $b unless $a && $a < $b;
                }
            }
        }

    }

    method $build_shift2 {

        use integer;

        foreach my $end ( $left->@* ) {

            my $z = $phi->[$end];
            while ( $z > 0 ) {

                my $a = $shift2->[$z];
                my $b = $depth->[$end];
                $shift2->[$z] = $b unless $a && $a < $b;

                $z = $phi->[$z];
            }
        }

        # Propagate once, after every pattern's chain has been applied: both steps only ever lower a value and
        # propagation flows parent-to-child, so a single top-down pass reaches the same fixpoint that a pass per
        # pattern did, in O(states) instead of O(patterns x states).

        $shift2->[0] = $min + 1; # note that $min is zero-based
        my @q = (0);

        while (@q) {
            my $r = shift @q;
            for my $c ( keys $states->[$r]->%* ) {
                push @q, my $s = $states->[$r]{$c};

                my $a = $shift2->[$s];
                my $b = $shift2->[$r] + 1;
                $shift2->[$s] = $b unless $a && $a < $b;
            }
        }

    }


    method search( $text, $callback ) {

        use integer;

        my @string = unpack( "U*", $text );
        my $n      = $#string;

        my $q = $min;
        my $c;

      TEXT: while ( $q <= $n ) {
            my $z = 0;
            while ( $q >= 0 && $states->[$z]{ $c = $string[$q] } ) {
                $z = $states->[$z]{$c};
                if ( defined $ends->[$z] ) {
                    $callback->( $q, $ends->[$z] ) or last TEXT;
                }
                $q--;
            }

            # calculate and memoise the failure shift.  A character that occurs in no pattern has no shift1 entry from
            # any state, so every such character takes the same shift from $z: memoise them under one shared key, or the
            # memo grows by one entry per (state, distinct character) ever seen in searched text and is never released.

            my $f = (
                $fails->[$z]{ $alpha->{$c} ? $c : -1 } //= do {
                    my $a = $shift1->[$z]{$c};
                    my $b = $shift2->[$z];
                    ( $a && $a < $b ) ? $a : $b;
                }
            );

            $q += $f;

            last if $q > $n;

        }

    }


    method matches( $text ) {

        my @matches;

        $self->search( $text, sub( $, $phrase ) { push @matches, $phrase; return 1; } );

        return @matches;
    }


    method first( $text ) {

        my $match;

        $self->search( $text, sub( $, $phrase ) { $match = $phrase; return 0; } );

        return $match;
    }


    method has_match( $text ) {
        my $match = "";

        $self->search( $text, sub( $, $ ) { $match = 1; return 0; } );

        return $match;
    }


    ADJUST :params ( :$patterns ) {

        if ( my @patterns = $patterns->@* ) {

            Carp::croak sprintf( "Parameter 'patterns' cannot contain empty strings for \%s constructor", ref($self) )
              if List::Util::any { !defined($_) || $_ eq "" } @patterns;

            $self->$enter($_) for @patterns;
        }
        else {
            Carp::croak sprintf("Parameter 'patterns' cannot be empty for \%s constructor", ref($self) );
        }

        $self->$build_phi;
        $self->$build_shift1;
        $self->$build_shift2;

    }

    sub BUILDARGS( $class, @args ) {

        if ( @args == 1 && ref( $args[0] ) eq "ARRAY" ) {
            return $class->SUPER::BUILDARGS( patterns => $args[0] );
        }

        return $class->SUPER::BUILDARGS(@args);
    }

}

1;

__END__

=pod

=encoding UTF-8

=for Pod::Coverage DOES META new

=for Pod::Coverage BUILDARGS

=for stopwords Aho Commentz Corasick Takeda Uratani

=head1 NAME

Algorithm::UrataniTakeda - an implementation of the Uratani-Takeda string searching algorithm

=head1 VERSION

version v0.1.7

=head1 SYNOPSIS

    use Algorithm::UrataniTakeda;

    use experimental qw( signatures ); # for Perl versions before v5.36

    my $m = Algorithm::UrataniTakeda->new( \@patterns );

    my $match = $m->first($text);

    my @all = $m->matches($text);

    if ( $m->has_match($text) ) {
        ...
    }

    sub callback( $pos, $phrase ) {
        ...
        return 1;
    }

    while (<STDIN>) {
        $m->search( $_, \&callback );
    }

=head1 STATUS

This is an experimental implementation.
It may not be correct.

=head1 DESCRIPTION

This is an implementation of the Uratani-Takeda algorithm for searching for multiple strings.

It combines the Aho-Corasick algorithm with the Boyer-Moore algorithm, and is similar to the Commentz-Walter algorithm.

=head1 ATTRIBUTES

=head2 patterns

    my $m = Algorithm::UrataniTakeda->new( patterns => \@patterns );

This is a required array reference of strings to search for.

It must not be empty or contain empty strings.

Since version v0.1.6, the constructor can be called with an array reference that is be assumed to be the patterns:

    my $m = Algorithm::UrataniTakeda->new( \@patterns );

=head1 METHODS

=head2 search

    sub callback( $pos, $phrase ) {
        ...
    }

    $m->search( $text, \&callback );

This searches the text and calls the callback function for every match.

If the callback returns a false value, it stops looking for additional matches.

=head2 matches

    my @matches = $m->matches( $text );

This returns an array of all matches.

If there are no matches, then it will return an empty array.

=head2 first

    my $match = $m->first( $text );

This returns the first match, or C<undef> if there are none.

=head2 has_match

    if ( $m->has_match( $text ) ) { ... }

This returns true if there is a match.

This was added in v0.1.2.

=head1 KNOWN ISSUES

When some of the L</patterns> are substrings other patterns, the order results returned by L</matches> or even L</first>
may not be consistent.

To ensure consistent ordering, you need to use the L</search> method with a custom sort.
For example, to to get the keywords sorted by position and then longest-match-first, use:

    my @raw;

    $m->search( $text, sub ( $pos, $phrase ) { push @raw, [ $pos, $phrase ] } );

    my @results =
      map { $_->[1] }
      sort { $a->[0] <=> $b->[0] || length( $b->[1] ) <=> length( $a->[1] ) }
      @raw;

=head1 SEE ALSO

This implementation was based on
Uratani N. and Takeda M.,
"A Fast String-Searching Algorithm for Multiple Patterns", B<Information, Processing & Management 29 (6)>, pp. 775-791, 1993.
L<doi:10.1016/0306-4573(93)90106-N>.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Algorithm-UrataniTakeda>
and may be cloned from L<https://github.com/robrwo/perl-Algorithm-UrataniTakeda.git>

=head1 SUPPORT

Only the latest release of this module will be supported.

This module requires Perl v5.26 or later.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Algorithm-UrataniTakeda/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
