# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;

package Data::Tabular::Table;

use Data::Tabular::Column;
use Carp qw (croak);

use Data::Tabular::Config::Output;

sub new
{
    my $caller = shift;
    my $class = ref($caller) || $caller;
    my $self = {};
    my $args = { @_ };
    my $old = {};

    if (my $table = $args->{table}) {
        for my $key (keys %$table) {
	   $old->{$key} = $table->{$key};
	}
	delete $args->{table};
    }

    if (ref($caller)) {
        for my $key (keys %$caller) {
	   $old->{$key} = $caller->{$key};
	}
    }
    $self = { %$old, %$args };
    bless $self, $class;

    die unless $self->{data};

    $self;
}

sub headers
{
    my $self = shift;

    $self->{headers};
}

sub columns
{
    my $self = shift;

    my @headers = $self->headers;

    my $x = 0;
    map({
	Data::Tabular::Column->new(
	    @_,
	    offset => $x++,
	    name => $_,
	    );
	} @headers);
}

sub _title
{
    my $self = shift;
    my $column_name = shift;
    my $title = q|/|. $column_name . q|/|;

warn "FIXME";
    $title;
}

sub header_offset
{
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


1;
__END__

=head1 NAME

Data::Tabular::Table

=head1 SYNOPSIS

This object is used by Data::Tabular to hold a table.

=head1 DESCRIPTION

=head2 Constructor

=over

=item new

This creates a table object. It requires a header and a data argument.

=back

=head2 Control Methods

=over

=item title

=item columns

=item headers

=item header_offset


=back

=head2 Display Methods

=over

=item html

returns html representation of the table;

=item xml

returns xml representation of the table;

=item xls

returns xls representation of the table;

=item txt

returns text representation of the table;

=back

=cut
