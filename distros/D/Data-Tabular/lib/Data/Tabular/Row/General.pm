# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
package
    Data::Tabular::Row::Totals;

use base 'Data::Tabular::Row';

use Carp qw(croak);

use overload '@{}' => \&array,
             '""'  => \&str;

sub str
{
    my $self = shift;
    'Row::Total';
}

sub group
{
    my $self = shift;
    $self->{group};
}

sub headers
{
    my $self = shift;
    $self->group->sum_list;
}

sub new_cell
{
    my $self = shift;
    my $args = {@_};
    die unless defined $args->{input_col};
    my $input_column = $args->{input_col};

    $self->{cols}->[$input_column] = {};
}

sub table
{
    shift->{table};
}

sub get
{
    my $self = shift;
    my $column_name = shift;
croak 'get';
    my $ret;
    $ret;
}

sub array
{
    my $self = shift;
croak;
    my $data = $self;
    $data = $data->[1];
    $data;
}

sub new
{
    
    my $caller = shift;
    my $class = ref($caller) || $caller;
    my $self = { @_ };
    if (ref($caller)) {
        croak(q|Don't know how to copy object: | . $class)
	    unless $caller->isa(__PACKAGE__);
	$self = $caller->clone();
    }
    $self = bless $self, $class;
die caller unless $self->table;
    $self;
}

sub attributes
{
die;
    my $self = shift;
    "x=" . join(':', keys %$self);
}

sub html_attribute_string
{
    my $self = shift;
    my $ret = "x=" . join(':', keys %$self);
    $ret = ' class="ende"';

    $ret;
}

sub selected
{
    my $self = shift;
    map({ $self->new_cell(data => $_, input_col => 1); } ('a', 'b'));
}

sub hdr
{
}

sub data
{
    my $self = shift;
    wantarray ? @{$self->[1]} : $self->[1];
}

sub id
{
    my $self = shift;
    $self->{row_id} || 'No ID available';
}

1;
__END__

