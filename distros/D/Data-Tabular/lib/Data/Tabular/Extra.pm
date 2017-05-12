# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
package
    Data::Tabular::Extra;

sub new
{
    my $class = shift;
    my $args = {@_};
    my $self = bless {}, $class;

    for my $arg (qw (row table)) {
	$self->{$arg} = $args->{$arg} || die 'No ' . $arg;
	delete $args->{$arg};
    }
    die q|Unknown argumet(s): |. join(' ', keys(%$args)) if keys(%$args);

    die unless $self->{row};
    die unless $self->{table};

    $self;
}

sub get
{
    my $self = shift;

    if (wantarray) {
	map({$self->{row}->get_column($_)} @_);
    } else {
        carp("only one column allowed in scalar context.") if @_ > 1;
	$self->{row}->get_column(shift);
    }
}

sub sum
{
    my $self = shift;
    my $total = 0;

    for my $column (@_) {
	my $data = $self->{row}->get_column($column);
	if (ref($data) eq 'HASH') {
die;
	    $data = $data->{html};
	}

	$total += $data;
    }

    require Data::Tabular::Type::Formula;

    Data::Tabular::Type::Formula->new(
	data => $total,
	columns => [ @_ ],
	type => 'sum',
    );
}

sub average
{
    my $self = shift;
    my $count = scalar(@_);

    my $total = 0;

    for my $column (@_) {
	$total += $self->{row}->get_column($column);
    }

    require Data::Tabular::Type::Formula;

    Data::Tabular::Type::Formula->new(
	data => $total / $count,
	columns => [ @_ ],
	type => 'average',
    );
}

sub row_id
{
    my $self = shift;

    $self->{row}{row_id};
}

sub _new_cell
{
    my $self = shift;
    my $args = { @_ };

    $args
}

1;
__END__

=head1 NAME

Data::Tabular::Extra

=head1 SYNOPSIS

This object is used by C<Data::Tabular> to create `extra'
columns on a table.

The subroutines in the `extra' section run under this package.

 ...
 extra => {
  'bob' => sub {
    my $self = shift;   # this is a Data::Tabular::Extra object
   }
 }
 ...

=head1 DESCRIPTION

This object is used to supply tools to the Data::Tabular designer.
It also helps to protect the data from that designer.

It is import to know that extra columns are created from left to
right.  Because of this you can use `extra' columns to create other
extra columns.  This means that you should order the extra columns
in the order that they need to be created in, and not in the the order
that they will be shown in the output.

=head2 Constructor

=over 

=item new()

The user should never need to call the constructor.

=back

=head1 METHODS

=over 4

=item get

Method to access the data for a column. Given a list of column names this method returns
a list of column data.  Extra columns are available after they have been generated.

=item sum

Method to sum a set of columns. Given a list of column names this method returns
the sum of those columns.  The type of the data returned is the type of the 
first column.

=item average

Method to sum a set of columns. Given a list of column names this method returns
the sum of those columns.  The type of the data returned is column type element,
but must conform to the Data::Tabular::Type::Frac constructor.

=back

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
