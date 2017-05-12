package Data::Transpose::Iterator::Base;

use strict;
use warnings;

use Moo;

=head1 NAME

Data::Transpose::Iterator::Base - Iterator for Data::Transpose.

This iterator provides basic methods for iteration, like number
of records (count) and getting next record (next).

=head1 SYNOPSIS

    $cart = [{isbn => '978-0-2016-1622-4',
              title => 'The Pragmatic Programmer',
              quantity => 1},
             {isbn => '978-1-4302-1833-3',
              title => 'Pro Git',
              quantity => 1},
            ];

    $iter = new Data::Transpose::Iterator::Base(records => $cart);

    print "Count: ", $iter->count, "\n";

    while ($record = $iter->next) {
	    print "Title: ", $record->title(), "\n";
    }

    $iter->reset;

    $iter->seed({isbn => '978-0-9779201-5-0',
                 title => 'Modern Perl',
                 quantity => 10});

=cut

sub BUILDARGS {
    my ( $class, @args ) = @_;

    if (@args == 1) {
        return {records => $args[0]};
    }
    else {
        return {@args};
    }
}

=head1 ATTRIBUTES

=head2 records

Creates a Data::Transpose::Iterator::Base object. The elements of the
iterator are hash references. They can be passed to the constructor
as array or array reference.

=cut

has records => (
    is => 'rw',
    trigger => 1,
);

=head2 count

Number of elements (if supported).

=cut

has count => (
    is => 'rwp',
    lazy => 1,
    default => sub {return 0;},
);

=head2 index

Current position (starting from 0).

=cut

has index => (
    is => 'rwp',
    lazy => 1,
    default => sub {return 0;},
);

=head1 METHODS

=head2 next

Returns next record or undef.

=cut

sub next {
	my ($self) = @_;
    my $index = $self->index;

	if ($index <= $self->count) {
        $self->_set_index($index + 1);
		return $self->records->[$index];
	}

	return;
};


=head2 reset

Resets iterator.

=cut

# Reset method - rewind index of iterator
sub reset {
	my ($self) = @_;

	$self->_set_index(0);

	return $self;
}

=head2 seed

Seeds iterator.

=cut

sub seed {
	my ($self, @args) = @_;

	if (ref($args[0]) eq 'ARRAY') {
		$self->records($args[0]);
	}
	else {
		$self->records(\@args);
	}

	return $self->count;
}

=head2 sort

Sorts records of the iterator.

Parameters are:

=over 4

=item $sort

Field used for sorting.

=item $unique

Whether results should be unique (optional).

=back

=cut

sub sort {
    my ($self, $sort, $unique) = @_;
    my (@data, @tmp);

    @data = sort {lc($a->{$sort}) cmp lc($b->{$sort})} @{$self->records};

    if ($unique) {
        my $sort_value = '';

        for my $record (@data) {
            next if $record->{$sort} eq $sort_value;
            $sort_value = $record->{$sort};
            push (@tmp, $record);
        }

        $self->records(\@tmp);
    }
    else {
        $self->records(\@data);
    }
}

sub _trigger_records {
    my ($self, $records) = @_;

	if (ref($records) eq 'ARRAY') {
		$self->_set_count(scalar @$records);
	}
	else {
		die "Arguments for records should be an arrayref.\n";
	}

    $self->reset;
 };

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
