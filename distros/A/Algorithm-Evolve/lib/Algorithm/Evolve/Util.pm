package Algorithm::Evolve::Util;

use strict;
use base 'Exporter';
use List::Util qw/shuffle/;
use Carp qw/croak carp/;

our $VERSION = '0.03';
our $UNICODE_STRINGS = 0;

our %EXPORT_TAGS = (
    str => [qw/str_crossover str_mutate str_agreement str_random/],
    arr => [qw/arr_crossover arr_mutate arr_agreement arr_random/],
);
our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;

sub str_crossover {
    my ($s1, $s2, $n_point) = @_;
    
    $n_point ||= 2;
    my $len    = length($s1);

    croak "Can't do ${n_point}-point crossover on length $len string"
        if $n_point >= $len;

    ## this allows for duplication of indices. maybe a fixme

    my @points = sort { $a <=> $b } map { int(rand $len) } 1 .. $n_point;
    push @points, $len if $n_point % 2;

    for (0 .. @points/2 - 1) {
        my ($x, $y) = @points[2*$_, 2*$_+1];
        (substr($s1, $x, $y-$x+1), substr($s2, $x, $y-$x+1)) =
            (substr($s2, $x, $y-$x+1), substr($s1, $x, $y-$x+1));
    }
    
    return ($s1, $s2);
}

sub str_agreement {
    my ($s1, $s2) = @_;

    ## substr is safe for unicode; xor'ing characters is not. But
    ## xor is about 30 times faster on longish strings...

    if ($UNICODE_STRINGS) {
        my $tally = 0;
        for (0 .. length($s1)-1) {
            $tally++ if substr($s1, $_, 1) eq substr($s2, $_, 1);
        }
        return $tally;
    }

    my $xor = $s1 ^ $s2;
    return $xor =~ tr/\x0/\x0/;
}

sub str_mutate {
    my ($string, $n, $alphabet) = @_;
    
    $n        ||= 1;
    $alphabet ||= [0,1];

    croak "Invalid alphabet"
        unless ref $alphabet eq 'ARRAY' and @$alphabet > 1;

    my $len = length($string);
    my @mutate_indices = $n < 1
        ? map { rand() < $n ? $_ : () } 0 .. $len-1
        : (shuffle 0 .. $len-1)[ 0 .. int($n)-1 ];
        
    for my $idx (@mutate_indices) {
        my $char                 = substr($string, $idx, 1);
        my @different            = grep { $char ne $_ } @$alphabet;
        substr($string, $idx, 1) = $different[ int(rand @different) ];
    }
    
    return $string;
}

sub str_random {
    my ($length, $alphabet) = @_;
    
    $alphabet ||= [0,1];

    return join '', map { $alphabet->[ rand @$alphabet ] } 1 .. $length;
}

##########################################

sub arr_crossover {
    my ($a1_ref, $a2_ref, $n_point) = @_;
    
    $n_point ||= 2;
    my @a1     = @$a1_ref;
    my @a2     = @$a2_ref;
    my $len    = @a1;

    croak "Can't do ${n_point}-point crossover on length $len array"
        if $n_point >= $len;

    ## this allows for duplication of indices. maybe a fixme

    my @points = sort { $a <=> $b } map { int(rand $len) } 1 .. $n_point;
    push @points, $len-1 if $n_point % 2;

    for (0 .. @points/2 - 1) {
        my ($x, $y)   = @points[2*$_, 2*$_+1];
        my @tmp       = @a1[$x .. $y];
        @a1[$x .. $y] = @a2[$x .. $y];
        @a2[$x .. $y] = @tmp;
    }
    
    return (\@a1, \@a2);
}

sub arr_agreement {
    my ($a1, $a2) = @_;

    my $tally = 0;
    for (0 .. $#{$a1}) {
        $tally++ if $a1->[$_] eq $a2->[$_];
    }

    return $tally;
}

sub arr_mutate {
    my ($arr_ref, $n, $alphabet) = @_;
    
    $n        ||= 1;
    $alphabet ||= [0,1];
    my @arr     = @$arr_ref;
    
    croak "Invalid alphabet"
        unless ref $alphabet eq 'ARRAY' and @$alphabet > 1;

    my $len = scalar @arr;
    my @mutate_indices = $n < 1
        ? map { rand() < $n ? $_ : () } 0 .. $len-1
        : (shuffle 0 .. $len-1)[ 0 .. int($n)-1 ];
    
    for my $idx (@mutate_indices) {
        my $char      = $arr[$idx];
        my @different = grep { $char ne $_ } @$alphabet;
        $arr[$idx]    = $different[ int(rand @different) ];
    }
    
    return \@arr;
}

sub arr_random {
    my ($length, $alphabet) = @_;
    
    $alphabet ||= [0,1];

    return [ map { $alphabet->[ rand @$alphabet ] } 1 .. $length ];
}


##########################################
##########################################
##########################################
1;
__END__

=head1 NAME

Algorithm::Evolve::Util - Some useful utility functions for use in evolutionary
algorithms.

=head1 SYNOPSIS

    use Algorithm::Evolve::Util ':str';
    use Algorithm::Evolve::Util ':arr';

=head1 SYNTAX

At the moment, this module only provides string- and array-mangling utilities.
They can be imported with the use arguments ':str' and ':arr' respectively.

In the following descriptions, a B<gene> refers to either a string or an
array reference. A position in the gene refers to a single character for string
genes and an array element for array genes.

=over 4

=item C<str_crossover( $string1, $string2 [, $N ] )>

=item C<arr_crossover( \@array1, \@array2 [, $N ] )>

Returns a random N-point crossover between the two given genes. C<$N> defaults
to 2. The two inputs should be the same length, although this is not enforced.
C<$N> must be also less than the size of the genes.

If you are unfamiliar with the crossover operation, it works like this: Lay
down the two genes on top of each other. Pick N positions at random, and cut
both genes at each position. Now swap every other pair of segments, and tape
the genes back up. So one possible 2-point crossover on the string genes
C<aaaaaa> and C<bbbbbb> would produce the two genes C<abbaaa> and C<baabbb>
(the two "cuts" here were after the 1st and 3rd positions).

=item C<str_agreement( $string1, $string2 )>

=item C<arr_agreement( \@array1, \@array2 )>

Returns the number of positions in which the two genes agree. Does not enforce
that they have the same size, even though the result is somewhat meaningless
in that case.

String gene comparison is done in a non-unicode-friendly way. To override this
and use a (slower) unicode-friendly string comparison, set 
C<$Algorithm::Evolve::Util::UNICODE_STRINGS> to a true value.

In array genes, the comparison of individual elements is done with C<eq>.

Note that this is the Hamming metric, and not the edit distance metric. Edit
distance may be an interesting fitness to use as well. There are at least two
modules (L<Text::Levenshtein|Text::Levenshtein> and 
L<Text::LevenshteinXS|Text::LevenshteinXS>) that I know of which calculate the
edit distance of two strings.

=item C<str_mutate( $string1 [, $num [, \@alphabet ]] )>

=item C<arr_mutate( \@array1 [, $num [, \@alphabet ]] )>

Returns a random mutation of the gene according to the given alphabet
(defaulting to {0,1}). If C<$num> is less than 1, it performs I<probabilistic
mutation>, with each position having a C<$num> probability of being mutated. If
C<$num> is greater than or equal to 1, it performs I<N-point mutation>: exactly
C<$num> positions are chosen at random and mutated. C<$num> defaults to 1. A
convenient rule of thumb is start with a mutation rate of 1/gene_length.

A mutation will always change the character in question: an 'a' will never be
chosen to replace an existing 'a' in a mutation. The following identity holds
for N-point mutations:

  str_agreement( str_mutate($some_string, $n, \@alph), $some_string )
    == length($some_string) - $n;

The alphabet for a string gene should consist of only single characters unless
you know what you're doing. Conceivably, you can implement an 'add' and 'remove'
mutation by using an alphabet that contains strings with length != 1. But this
seems a little hackish to me. For array genes, the alphabet can be just about
anything meaningful to you.

=item C<str_random( $size [, \@alphabet ] )>

=item C<arr_random( $size [, \@alphabet ] )>

Returns a random gene of the given size over the given alphabet, defaulting to
{0,1}.

=back

=head1 SEE ALSO

L<Algorithm::Evolve|Algorithm::Evolve>

F<StringEvolver.pm> in the F<examples/> directory uses the utilities in
Algorithm::Evolve::Util to implement a completely generic simple string
evolver critter class in very few lines of code.

=head1 AUTHOR

Algorithm::Evolve is written by Mike Rosulek E<lt>mike@mikero.comE<gt>. Feel 
free to contact me with comments, questions, patches, or whatever.

=head1 COPYRIGHT

Copyright (c) 2003 Mike Rosulek. All rights reserved. This module is free 
software; you can redistribute it and/or modify it under the same terms as Perl 
itself.
