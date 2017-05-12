# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
package Data::Tabular::Config::Output;

sub new
{
    my $caller = shift;
    my $class = ref($caller) || $caller;

    my $self = bless { @_ }, $class;
    $self->{caller} = join(':', caller);

    $self->{xls} ||= {};
    $self->{html} ||= {};

    if ($self->{titles}) {
        for my $column (keys %{$self->{titles}}) {
	    if ($self->{columns}{$column}{title} and $self->{columns}{$column}{title} ne $self->{titles}->{$column}) {
use Data::Dumper;
die Dumper $self;
	    }
            $self->{columns}{$column}{title} = $self->{titles}->{$column};
	}
    }

    die 'No column list' unless $self->column_list;
    $self;
}

sub column_list
{
    my $self = shift;
    wantarray ? @{$self->{headers}} : $self->{headers};
}

sub col_id
{
    my $self = shift;
    my $col_name = shift;

    my $x = 0;
    for my $col ($self->column_list) {
	if ($col eq $col_name) {
	    return $x;
	}
	$x++;
    }
    die "Unknown column $col_name";
}

sub title
{
    my $self = shift;
    my $column_name = shift;
    $self->{columns}->{$column_name}->{title} || $column_name;
}

sub html_column_attributes
{
    my $self = shift;
    my $column_name = shift;
    my $ret = {
	%{$self->{columns}->{$column_name}->{html_attributes} || {}},
    };
    $ret->{align} = 'right';
    if (my $width = $self->{columns}->{$column_name}->{width}) {
        die if defined $ret->{width};
	$ret->{width} = $width;
    }
    return $ret;
}

sub xls_width
{
    my $self = shift;
    my $column_name = shift;
    $self->{columns}->{$column_name}->{xls}->{width} || $self->{xls}->{width} || 10;
}

sub xls_title_format
{
    my $self = shift;
    my $column_name = shift;

    $self->{columns}->{$column_name}->{xls}->{title_format};
}

sub align
{
    my $self = shift;
    my $column_name = shift;
    $self->{columns}->{$column_name}->{align};
}

sub headers
{
    my $self = shift;

    @{$self->{headers}};
}

sub html_attribute_string
{
    my $self = shift;
    my $attributes = {
        border => 1,
    };
    my $na = $self->{html}->{attributes};
    for my $attribute (sort keys %$na) {
	$attributes->{$attribute} = $na->{$attribute};
    }

    my $ret = '';
    for my $attribute (sort keys %$attributes) {
        next unless $attributes->{$attribute};
	$ret .= qq| $attribute="| . $attributes->{$attribute} . qq|"|;
    }

    $ret;
}

sub test_xls_attribute
{
    my $self = shift;
    my $attribute = shift;
    return $self->{xls}->{$attribute};
}

sub table
{
    shift->{title};
}

sub set_type
{
    my $self = shift;
    my $args = { @_ };

    $self->{types}->{$args->{name}} = $args->{type};

    undef;
}

sub type
{
    my $self = shift;
    my $name = shift;

    $self->{types}->{$name} || 'text';
}

sub set_column_format
{
    my $self = shift;
    my %args = @_;

    for my $key (keys %args) {
	$self->{format}{$key} = $args{$key};
    }
}

sub get_column_format
{
    my $self = shift;
    my $column = shift or die 'need name';

    $self->{format}{$column} || '%s';
}

sub format
{
    'bob';
}

sub set_use_functions
{
    warn "set_use_functions";
}

sub get_use_functions
{
    warn "get_use_functions";
}

1;
__END__

This parses and stores the output infomation.


