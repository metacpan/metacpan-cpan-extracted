use strict;
package Algorithm::GenerateSequence;
use vars qw( $VERSION );
$VERSION = '0.02';

=head1 NAME

Algorithm::GenerateSequence - a sequence generator

=head1 SYNOPSIS

 my $gen = Algorithm::GenerateSequence->new(
    [qw( one two three )], [qw( hey bee )],
 );
 print join(' ', $gen->next), "\n"; # one hey
 print join(' ', $gen->next), "\n"; # one bee
 print join(' ', $gen->next), "\n"; # two hey
 print join(' ', $gen->next), "\n"; # two bee
 ...

=head1 DESCRIPTION

Algorithm::GenerateSequence provides an iterator interface to a
sequence you define in terms of the symbols to use in each position.

You may use a different amount of symbols in each position and the
module will iterate over them correctly.  This might be useful in
identifying all the cards in a deck:

 my $deck = Algorithm::GenerateSequence->new(
     [qw( Heart Diamond Spade Club )],
     [qw( A 2 3 4 5 6 7 8 9 10 J Q K )],
 );

Or for a range of addresses to scan:

 my $scan = Algorithm::GenerateSequence->new(
     [192], [168], [0..254], [1]
 );

=head1 METHODS

=head2 new( @values );

@values contains arrays of symbols which will be used to form the
sequence

=cut

sub new {
    my $class = shift;

    my @values = @_;
    my @counters = (0) x @values;
    my ($started, $ended);

    bless sub {
        return if $ended;

        if ($started++) {
            my $max = $#counters;

            # mmm, long addition
            do {
                my $new = ++$counters[ $max ];
                # check for overflow
                goto DONE if $new % @{ $values[ $max ] };
                $counters[ $max ] = 0;
            } while --$max >= 0;
          DONE:
            if ($max < 0) {
                $ended = 1;
                return;
            }
        }

        my $i = 0;
        return map { $values[ $i++ ][ $_ ] } @counters;
    }, ref $class || $class;
}

=head1 next

returns a list containing the next value in the sequence, or false if
at the end of the sequence

=cut

sub next { $_[0]->() }


=head2 as_list

return the remainder of the sequence as a list of array references

=cut

sub as_list {
    my $self = shift;

    my @results;
    while (my @next = $self->()) {
        push @results, \@next;
    }
    return @results;
}

1;
__END__

=head1 BUGS

None currently known.  If you find any please make use of
L<http://rt.cpan.org> by mailing your report to
bug-Algorithm-GenerateSequence@rt.cpan.org, or contact me directly.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright (C) 2003 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
