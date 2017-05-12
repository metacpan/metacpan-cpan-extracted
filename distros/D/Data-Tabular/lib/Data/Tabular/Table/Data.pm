# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
package
    Data::Tabular::Table::Data;

use base 'Data::Tabular::Table';

use Data::Tabular::Type;

use Carp qw (croak);

sub new
{
    my $caller = shift;

    my $self = $caller->SUPER::new(@_);

    $self;
}

sub row_count
{
    shift->_row_count;
}

sub _row_count
{
    my $self = shift;

    scalar(@{$self->{data}->{rows}});
}

sub headers
{
    my $self = shift;

    @{$self->{data}->{headers}};
}

sub all_headers
{
    my $self = shift;

    $self->{_all_headers} ||= [ @{$self->{data}->{headers} || []} ];
    my @headers = @{$self->{_all_headers}};

    @headers;
}

sub get_row_column
{
    my $self = shift;
    my $row = shift;
    my $column = shift;
    my $count = scalar(@{$self->{data}->{headers}});
    my $ret;
    if ($column >= $count) {
warn caller;
        $ret = 'Column too great';
    } else {
	$ret = $self->{data}->{rows}->[$row][$column];
    }

    if (my $type = $self->{data}->{types}[$column]) {
        unless (ref $ret) {
	    $type = "Data::Tabular::Type::$type";
	    $ret = bless({ data => $ret }, $type);
        }
    }

    return $ret;
}

sub get_row_column_name
{
    my $self = shift;
    my $row = shift;
    my $column_name = shift;
    my $count = scalar(@{$self->{data}->{headers}});
    my $column;
    my $ret;

    for ($column = 0; $column < $count; $column++) {
        last if $self->{data}->{headers}->[$column] eq $column_name;
    }

    if ($column >= $count) {
        $ret = 'Unknown Column '. $column_name;
    } else {
	$ret = $self->{data}->{rows}->[$row][$column];
    }

    if (my $type = $self->{data}->{types}[$column]) {
        unless (ref $ret) {
	    $type = "Data::Tabular::Type::$type";
	    $ret = bless({ data => $ret }, $type);
        }
    }

    return $ret;
}

sub row_package
{
    require Data::Tabular::Row::Data;

   'Data::Tabular::Row::Data';
}

sub rows
{
    my $self = shift;
    my $args = { @_ };
    my @ret;

    die 'Need output' unless $args->{output};

    for (my $row = 0; $row < $self->_row_count; $row++) {
	push(@ret, $self->row_package->new(
	    table => $self,	# FIXME: This is very bad!
	    input_row => $row,
	    extra => $self->{extra},
	    output => $args->{output},
	    row_id => $row + 1,
	));
    }

    $self->{rows} = \@ret;
    wantarray ? @{$self->{rows}} : $self->{rows};
}

1;
__END__

=head1 NAME

Data::Tabular::Table::Data - 

=head1 SYNOPSIS

This object is used by Data::Tabular to hold a table.

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=over 4

=item new

=back

=head2 METHODS

=over 4

=item rows

=item get_row_column

=item get_row_column_name

=item row_count

=item all_headers

=item row_package

=item headers

=back

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=head1 COPYRIGHT

Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Data::Tabular>, L<Data::Tabular::Table>

=cut
