# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;

package
    Data::Tabular::Row::Extra;

use base 'Data::Tabular::Row';

use Carp qw (croak);

sub new
{
    my $caller = shift;
    my $self = $caller->SUPER::new(@_);

    croak unless $self->{extra};

    $self;
}

sub get_column
{
    my $self = shift;
    my $column_name = shift;
    my $ret;

    my $row    = $self->{input_row};

    if ($self->table()->is_extra($column_name)) {
        die "circulare reference for $column_name (" . join(' ', @{$self->{last}}) . ')' . Dumper $self . join(' ', caller) if $self->{_working}->{$column_name}++;
	push(@{$self->{last}}, $column_name);
	$ret = $self->extra_column($self, $column_name);
	pop(@{$self->{last}});
        $self->{_working}->{$column_name} = 0;
    } else {
	$ret = $self->table()->get_row_column_name($row, $column_name);
    }

    $ret = Data::Tabular::Type::Text->new(data => $ret);

    $ret;
}

sub extra_package
{
    require Data::Tabular::Extra;
    'Data::Tabular::Extra';
}

sub get
{
    my $self = shift;
    $self->get_column(@_);
}

sub extra_column
{
    my $self = shift;
    my $row = shift;
    my $key = shift;

    my $extra = $self->{extra}->{columns};

    my $ret = undef;

    my $x = $self->extra_package->new(row => $row, table => $self);

    if (ref($extra->{$key}) eq 'CODE') {
        eval {
            $ret = $extra->{$key}->($x);
        };
        if ($@) {
            die $@;
        }
    } else {
        die 'Only know how to deal with code';
    }
    if (my $t = ref($ret)) {
        if ($t eq 'HASH') {
#            $ret;
        } elsif ($t eq 'ARRAY') {
die	    $t;
        } elsif ($t eq 'SCALAR') {
die	    $t;
        } elsif ($t eq 'CODE') {
die	    $t;
	} else {
#	    $ret;
	}
    } else {
        $ret = $self->set_type($ret, $key);
    }
    
    $ret;
}

sub set_type
{
    my $self = shift;
    my $date = shift;
    my $key = shift;

    Data::Tabular::Type::Text->new(data => $date);
}

sub type
{
    'normal data';
}

1;
__END__
