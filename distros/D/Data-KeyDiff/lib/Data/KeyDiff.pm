package Data::KeyDiff;

use warnings;
use strict;

=head1 NAME

Data::KeyDiff - Diff one set/list against another with a key basis

=head1 VERSION

Version 0.021

=cut

$Data::KeyDiff::VERSION = '0.021';

=head1 SYNOPSIS

    # For each item in the list, the number is the item "key", the letter is the item "data"
    my @A = qw/1a 2b 3c 4d 5e 6f/;
    my @B = qw/5e 1f 2b 3r 4d 7q j n/;

    use Data::KeyDiff qw/diff/;
    
    diff( \@A, \@B,
        key =>
            sub($item) {
                # Return the leading number from $item
            },

        is_different =>
            sub($a, $b) {
                # Is the letter on $a different from $b?
            },

        is_new =>
            sub($item) {
                # Does $item already have a key?
            },

        # "j" and "n" are new!
        new => sub($element) {
            # Handle a new $element 
        },

        # "7q" was inserted (already had a key)
        insert => sub($element) {
            # $element was "inserted" into @B
        },

        # "1f" and "3r" were updated
        update => sub($element) {
            # $element was "update" in @B
        },

        # "6f" was deleted
        delete => sub($element) {
            # $element was "deleted" in @B
        },
        
        # "5e", "2b", and "4d" changed rank
        update_rank => sub($element) {
            # $element had it's rank changed in @B
        },
    );

=head1 DESCRIPTION 

Data::KeyDiff performs a diff-like operation on sets that have unique keys associated with each element.
Instead of looking at the whole list, C<diff> looks at each element on a case-by-case basis to see whether it's state or
inclusion has changed from the "before" set to the "after" set.

=head1 METHODS

=head2 Data::KeyDiff->diff( <before-set>, <after-set>, <configuration> )

Compare the before-set to the after-set. Call handlers in <configuration> as defined.

Besides the before-set and after-set, this method accepts the following:

=over

=item ignore($item) OPTIONAL

A subroutine that returns true if $item should be ignored (e.g. commented). If an item ignored, the rank counter is not incremented, but the position counter still is.

=item prepare($item) OPTIONAL

A subroutine that returns a replacement for $item in further processing. Basically, this allows you to preprocess the $item before passing it to C<key>, C<is_different>, etc.

=item is_new($item)

A subroutine that returns true if $item is "new" and so doesn't already have a key.
Note, this subroutine is not run on the before-set (every item in that set should already have a key).

=item key($item) 

A subroutine that returns the key of $item.

=item is_different($before_item, $after_item, $before_element, $after_element) 

=item compare($before_item, $after_item, $before_element, $after_element) 

A subroutine that returns true if $before_item is different from $after_item.

=item new($element) OPTIONAL

Called for each new $element

=item insert($element) OPTIONAL

Called for each $element that should be inserted

=item update($element) OPTIONAL

Called for each $element that should be updated

=item update_rank($element) OPTIONAL

Called for each $element that is otherwise the same, but has a different rank

=item delete($element) OPTIONAL

Called for each $element that should be deleted

=back

=head1 EXPORTS

=head2 diff( ... )

Same syntax as above. See above for more information.

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-keydiff at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-KeyDiff>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::KeyDiff


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-KeyDiff>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-KeyDiff>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-KeyDiff>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-KeyDiff>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

use Data::KeyDiff::Element;
use Carp;

require Exporter;
@Data::KeyDiff::ISA = qw/Exporter/;
@Data::KeyDiff::EXPORT_OK = qw/diff/;

sub diff {
    shift if $_[0] && $_[0] eq __PACKAGE__;
    my $before = shift;
    my $after = shift;
    my %in = @_;

    my $get_key = $in{key} || $in{get_key} || sub {
        return shift;
    };
    my $is_new = $in{is_new};
    my $prepare = $in{prepare};
    my $is_different = $in{is_different} || $in{compare} || sub {
        my $left = shift;
        my $right = shift;
        return ((defined $left ^ defined $right) || (defined $left && $left ne $right));
    };
    my $ignore = $in{ignore};
    my ($on_new, $on_insert, $on_update, $on_update_rank, $on_delete) = @in{qw/new insert update update_rank delete/};

    my %before;
    my %after;
    my (@new, %insert, %update, %update_rank, %delete);

    my $position = my $rank = 0;
    $position--;
    my $item;
    for $item (@$before) {
        $position++;
        next if $ignore && $ignore->($item);
        my $value = $prepare ? $prepare->($item) : $item;
        my $key = $get_key->($value, $item);
        my $element = Data::KeyDiff::Element->new(key => $key, value => $value, position => $position, rank => $rank++, item => $item, in_before => 1);
        $before{$key} = $element;
    }

    $position = $rank = 0;
    $position--;
    for $item (@$after) {
        $position++;
        next if $ignore && $ignore->($item);
        my $value = $prepare ? $prepare->($item) : $item;
        if ($is_new && $is_new->($value, $item)) {
            my $element = Data::KeyDiff::Element->new(value => $value, position => $position, rank => $rank++, item => $item, is_new => 1);
            push @new, $element;
            next;
        }
        my $key = $get_key->($value, $item);
        my $element = Data::KeyDiff::Element->new(key => $key, value => $value, position => $position, rank => $rank++, item => $item, in_after => 1);
        $after{$key} = $element;
        if (! $before{$key}) {
            $insert{$key}++;
        }
        elsif ($is_different->($before{$key}->value, $element->value, $before{$key}, $element)) {
            $update{$key}++;
        }
        elsif ($before{$key}->rank != $after{$key}->rank) {
            $update_rank{$key}++;
        }
    }

    for my $key (keys %before) {
        next if exists $after{$key};
        $delete{$key}++;
    }

    if ($on_new) {
        $on_new->($_) for @new;
    }

    if ($on_insert) {
        $on_insert->($after{$_}) for keys %insert;
    }

    if ($on_update) {
        $on_update->($after{$_}, $before{$_}) for keys %update;
    }

    if ($on_update_rank) {
        $on_update_rank->($after{$_}, $before{$_}) for keys %update_rank;
    }

    if ($on_delete) {
        $on_delete->($before{$_}) for keys %delete;
    }
}

1; # End of Data::KeyDiff
