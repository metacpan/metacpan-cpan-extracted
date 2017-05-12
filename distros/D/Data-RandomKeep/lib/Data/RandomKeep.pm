package Data::RandomKeep;

=head1 NAME

Data::RandomKeep - Randomly keep a given number of offered items.

=head1 SYNOPSIS

    use Data::RandomKeep;

        # Keep 10 random lines from a file.
    my $lines_keeper = Data::RandomKeep->new(10)
    $lines_keeper->offer($_) while <$file_hdl>;
    my $kept_lines_array_ref = $lines_keeper->kept();

        # Select 6 numbers out of 49 as a pick for a lottery ticket.
    my $numbers_keeper = Data::RandomKeep->new(6);
    $numbers_keeper->offer(1 .. 49);
    print "This might win: @{$numbers_keeper->kept()}\n";

=head1 DESCRIPTION

Suppose you want to keep ten random lines from a file. You might read
all the lines in an array, shuffle it, and keep the first ten lines,
but that can be quite wasteful, especially if the file is big. This
module implements the task in a more efficient manner.

To use the module, you first instantiate a Data::RandomKeep object,
telling the constructor how many items you will want to keep. Then you
offer() it items, which the object will keep or discard, with correct
randomness. At any moment, you can look at the items that have been
kept up to that point, using the kept() method.

=head1 METHODS

=cut

# --------------------------------------------------------------------
use strict;
use warnings;

our $VERSION = '0.02';

# --------------------------------------------------------------------

=head2 $pkg->new ($nb_to_keep)

Returns a ref to a newly created Data::RandomKeep object, designed to
keep a maximum of $nb_to_keep items. If $nb_to_keep is not defined, a
single item will eventually be kept.

=cut

sub new {
    my ($pkg, $nb_to_keep) = @_;
    return bless {
        nb_to_keep  => $nb_to_keep || 1,
        nb_seen     => 0,
        nb_kept     => 0,
        kept        => [],
    }, $pkg;
}

# --------------------------------------------------------------------

=head2 $self->offer (@items)

Offers @items for inclusion into the set of kept items. The decision
to keep it will be statistically correct, given the total number of
items the instance is supposed to keep and the number of items offered
so far.

=cut

sub offer {
    my ($self, @items) = @_;
    for my $item (@items) {
        ++$self->{nb_seen};
        if (rand() < $self->{nb_to_keep} / $self->{nb_seen}) {
            $self->{kept}[
                $self->{nb_kept} < $self->{nb_to_keep}
                    ? $self->{nb_kept}++
                    : rand($self->{nb_to_keep})
            ] = [$self->{nb_seen}, $item];
        }
    }
}

# --------------------------------------------------------------------

=head2 $self->kept ()

Returns a ref to an array of the items kept so far. The items will be
in the same order in which they were originally offered.

=cut

sub kept {
    my ($self) = @_;
    return [
        map {
            $_->[1]
        }
        sort {
            $a->[0] <=> $b->[0]
        } @{$self->{kept}}
    ];
}

# --------------------------------------------------------------------
1;

=head1 AUTHOR

Luc St-Louis, E<lt>lucs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Luc St-Louis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

