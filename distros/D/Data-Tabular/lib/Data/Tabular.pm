# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
use warnings;

package Data::Tabular;

our $VERSION = '0.29';

use Carp qw (croak);

use Data::Tabular::Group;
use Data::Tabular::Table::Extra;
use Data::Tabular::Table::Data;
use Data::Tabular::Config::Output;
use Data::Tabular::Config::Extra;
use Data::Tabular::Extra;

sub new
{
    my $caller = shift;
    my $class = ref($caller) || $caller;
    my $self = bless { @_ }, $class;

    my $extra  = Data::Tabular::Config::Extra->new(
	headers => $self->{extra_headers}, 
	columns => $self->{extra}, 
	types => $self->{extra_types}, 
    );

    if (ref($caller)) {
        die q|Don't know how to copy object.|
	    unless $caller->isa(__PACKAGE__);
	$self = $caller->clone()
    }
    my $count = 0;
    if ($self->{headers}) {
        $self->{_all_headers} = [ (@{$self->{headers} || []}, @{$self->{extra_headers} || []}) ];
        for my $elm (@{$self->{_all_headers}}) {
	    $self->{_header_off}->{$elm} = $count++;
	}
    }
    $self->{data_table} =
	Data::Tabular::Table::Data->new(
	    data => bless({
		headers => $self->{headers},
		rows    => $self->{data},
		types   => $self->{types},
	    }, 'Data::Tabular::Data'),
	);
    $self->{extra_table} =
	 Data::Tabular::Table::Extra->new(
            table => $self->{data_table},
	    extra => $extra,
	);
    $self->{group_by} ||= {};
    if (my $group_by = $self->{group_by}) {
        if (ref $group_by eq 'HASH') {
	    $self->{grouped_table} = Data::Tabular::Group->new(
		table => $self->{extra_table},
		title => $self->{title} || 1,
		%$group_by
	    );
	} else {
	    die "group_by data must be a hash.";
	}
    } else {
die "FIXME";
	$self->{grouped_table} = $self->{extra_table};
    }
    $self;
}

sub headers
{
    my $self = shift;

    $self->{extra_table}->headers;
}

sub output
{
    my $self = shift;
    my $args = { %{$self->{output} || {}}, @_ };

    my $output = Data::Tabular::Config::Output->new(
        headers => [ @{$self->{headers}},
	    $self->{extra_headers} ? @{$self->{extra_headers}} : keys %{$self->{extra}} ],
	%$args,
    );
    $output;
}

sub grouped
{
    my $self = shift;

    $self->{grouped_table};
}

sub extra_table
{
    my $self = shift;

    $self->{extra_table};
}

sub data_table
{
    my $self = shift;

    $self->{data_table};
}

sub html
{
    my $self = shift;

    require Data::Tabular::Output::HTML;

    return Data::Tabular::Output::HTML->new(
        table => $self->grouped,
	output => $self->output,
	@_,
    );
}

sub xls
{
    my $self = shift;
    require Data::Tabular::Output::XLS;

    return Data::Tabular::Output::XLS->new(
	table => $self->grouped,
	output => $self->output,
	@_,
    );
}

sub txt 
{
    my $self = shift;
    require Data::Tabular::Output::TXT;

    return Data::Tabular::Output::TXT->new(
	table => $self->grouped,
	output => $self->output,
	@_,
    );
}

sub csv 
{
    my $self = shift;
    require Data::Tabular::Output::CSV;

    return Data::Tabular::Output::CSV->new(
	table => $self->grouped,
	output => $self->output,
	@_,
    );
}

1;
__END__

=head1 NAME

Data::Tabular - Handy Table Manipulation and rendering Object

=head1 SYNOPSIS

 use Data::Tabular;

 $table = Data::Tabular->new(
     headers => ['one', 'two'],
     data    => [
          ['a', 'b'],
          ['c', 'd']
     ],
     extra_headers => [ 'three' ],
     extra => {
         'three' => sub {
             my $self = shift;
             my $a = $self->get('one');
             my $b = $self->get('two');
             $a . $b;
         },
     },
     group_by => {
     },
     output => {
         headers => [ 'three', 'one', 'two' ],
     },
 );


=head1 DESCRIPTION

Data::Tabular has four major sections:

The data section.  This is the base table, it contains a set of rows that is made up of 
named columns.

The extra section. This is a set of named columns that are added to the table.

The group_by section. This is allows titles, and subtotals to be inserted into table.

The output section.  This allows the output to be formatted and rendered for a particular
type of output.  Currently HTML and Excel spreadsheets are supported.

Of these only the data section is required.

=head1 Data Section

The Data section consists of two pieces of information a list of headers names and 
a 2 dimensional array of data.

=head1 API

=head2 Constructor

=over

=item new

The new method

=back

=head2 Output Control Methods

=over

=item output

Get the output object.

=back

=head2 Accessor Methods

=over

=item data_table

The data method returns a Data::Table object.

=item extra_table

The extra method returns a Data::Table::Extra object.

=item grouped_table

The grouped method returns a Data::Table::Grouped object.

=item grouped

The grouped method returns a Data::Table::Grouped object.

=item headers

The headers method returns the available headers in the
Data::Table::Extra object. This is the headers from both the data
section and the extra section. These are the headers that can be in the
output section.

=back

=head2 Configure Methods

=head2 Display Methods

=over

=item html

returns html representation of the table.

=item xls

returns xls representation of the table.

=item txt

returns text representation of the table.

=item csv

returns a comma separated representation of the table.

=back

=head1 EXAMPLES

 my $st = $dbh->prepare('Select * from my_test_table');
 my $data = selectall_arrayref($st);
 my $headers = $st->{NAMES}
 
 my $table = Data::Tabular->new(
     data => $data,
     headers => $headers,
 );

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=head1 COPYRIGHT

Copyright (C) 2003-2008, G. Allen Morris III, all rights reserved

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Data::Tabular::Table>

=cut

