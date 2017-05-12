# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
package
    Data::Tabular::Table::Extra;

use base 'Data::Tabular::Table::Data';

use Carp qw (croak);

sub new
{
    my $caller = shift;
    my $self = $caller->SUPER::new(@_);

    $self->{_all_headers} = [ (@{$self->{data}->{headers} || []}, sort keys(%{$self->extra->{columns} || {}})) ];

    $self;
}

sub extra
{
    my $self = shift;

    $self->{extra};
}

sub is_extra
{
    my $self = shift;
    my $column_name = shift;

    exists $self->extra->{columns}->{$column_name};
}

sub headers
{
    my $self = shift;

    @{$self->{_all_headers}};
}

sub all_headers
{
    my $self = shift;

    $self->{_all_headers} = [ (@{$self->{data}->{headers} || []}, sort keys(%{$self->extra->{columns} || {}})) ];

    @{$self->{_all_headers}};
}

sub row_package
{
    require Data::Tabular::Row::Extra;
   'Data::Tabular::Row::Extra';
}

sub header_offset
{
die;
    my $self = shift;
    my $column = shift;
    my $count = 0;
    unless ($self->{_header_off}) {
	for my $header ($self->headers) {
	    $self->{_header_off}->{$header} = $count++;
	} 
    }
    my $ret = $self->{_header_off}->{$column};
    croak "column '$column' not found in [",
          join(" ",
	      sort keys(%{$self->{_header_off}})
	  ), ']' unless defined $ret;
    $ret;
}

sub get_row_column
{
    my $self = shift;
    my $row = shift;
    my $column = shift;
    my $count = scalar(@{$self->{data}->{headers}});

    if ($column >= $count) {
        die 'column out of range';
    } else {
	$self->{data}->{rows}->[$row][$column];
    }
}

sub extra_column
{
    my $self = shift;
    my $row = shift;
    my $key = shift;
    my $ret = 'N/A';
die;
    my $extra = $self->{extra};

    return undef unless $row;

    my $offset = $self->header_offset($key);

    my $x = $self->extra_package->new(row => $row, table => $self);

    if (ref($extra->{$key}) eq 'CODE') {
	eval {
	    $ret = $extra->{$key}->($x);
	};
	if ($@) {
	    die $@;
	}
    } else {
	die 'only know how to deal with code';
    }
    die $ret;
    if (ref($ret)) {
        die if (ref($ret) eq 'HASH');
    }

    $ret;
}

1;
__END__

=head1 NAME

Data::Tabular::Table::Extra

=head1 SYNOPSIS

This object is used by Data::Tabular to hold a table with calculated columns.

=head1 DESCRIPTION

This object holds a table that has calculated columns.

=head1 METHODS

=over 4

=item is_extra

The is extra method is used by underlying row to decide if a column needs to be
calculated.

=back

=head1 SEE ALSO

 Data::Tabular::Row::Extra

=cut
