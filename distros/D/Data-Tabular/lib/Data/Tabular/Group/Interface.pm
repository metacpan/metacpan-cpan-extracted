# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
package
    Data::Tabular::Group::Interface;

sub new
{
    my $class = shift;
    my $self = bless { @_ }, $class;

    die 'A group field is required' unless defined $self->{group};

    $self;
}

sub get
{
    my $self = shift;
    my $column_name = shift;

    $self->{group}->get($column_name);
}

sub count
{
    my $self = shift;
    scalar $self->{group}->raw_rows();
}

sub header
{
    my $self = shift;
    my $args = { @_ };
    require Data::Tabular::Row::Header;
    Data::Tabular::Row::Header->new(
	text => $args->{text},
	table => $self->{group},
    );
}

sub titles
{
    my $self = shift;
    require Data::Tabular::Row::Titles;

    Data::Tabular::Row::Titles->new(
	@_,
	table => $self->{group},
    );
}

sub totals
{
    my $self = shift;
    my $args = { @_ };
    require Data::Tabular::Row::Totals;
    my $sum_list = $args->{sum_list} || $self->{group}->{group}->{sum_list};
    die('Need sum list') unless $sum_list;

    Data::Tabular::Row::Totals->new(
	text => $args->{title},
	table => $self->{group},
        sum_list => $sum_list,
        extra => $self->{group}->{group}->{extra},
    );
}

*sum = \&totals;

sub averages
{
    my $self = shift;
    my $args = { @_ };
    require Data::Tabular::Row::Averages;
    my $sum_list = $args->{sum_list} || $self->{group}->{group}->{sum_list};

    Data::Tabular::Row::Averages->new(
	text => $args->{title},
	table => $self->{group},
        sum_list => $sum_list,
        extra => $self->{group}->{group}->{extra},
    );
}

*avg = \&averages;

1;
__END__

=head1 NAME

Data::Tabular::Group::Interface - Object that is passed into I<group_by> methods

=head1 SYNOPSIS

   group_by => {
       groups => [
          {
	     pre => sub {
	          my $self = shift;    # This is a Data::Tabular::Group::Interface object
	     },
	  }
       ],
    },

=head1 DESCRIPTION

C<Data::Tabular::Group::Interface> is only used by the I<group_by> function of the
C<Data::Tabular> package.

There are several 2 major groups of methods in this object: access
methods and output methods. Access methods let the users groups methods
access information about the current table and the output methods that
return the rows that are being inserted into the table. 

=head2 Constructor

=over 

=item new()

The user should never need to call the constructor.

=back

=head2 Access Methods

=over 

=item get([column name])

This method returns the value of the column given by I<column name>.  This column should
be a grouped column or the value will unpredictable (one of the values from the group).

=item count

This give the number of input rows in the current group.

=back

=head2 Output Methods

=over 2

=item header(text => 'header text')

The header method returns a header row that will span the complete table.

=back

=head3 Arguments

=over 2

=item text

The text that is printed in the header.  Often get() and count() are used
to build this string.

=item titles

The titles method returns a row of titles. Normally all tables will use
this method at least once.

=item totals/sum

This method return a row with the columns listed in the I<sum array> summed.

=back

=over

=item averages/avg

This is similar to the totals method, but each value is divided by the
number of input rows before being output.

=back

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
