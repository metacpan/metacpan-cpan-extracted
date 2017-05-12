# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
package
    Data::Tabular::Row::Function;

use base 'Data::Tabular::Row';

use Carp qw(croak carp);

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    die unless $self->table;
    die "Need sum_list" unless $self->{sum_list};

    $self;
}

sub cells
{
    my $self = shift;
    my @ret = ();
    my @headers = $self->headers();

    my $offset = 0;
    my $hash;
    for my $x ( @{$self->{sum_list} || []} ) {
        $hash->{$x} = { sum => 1 };
    }

    my $start;
    my $x = 0;
    my $state = 0;
    my $cols = 1;
    while (my $column_name = shift @headers) {
        if ($state == 0) {
	    if ($column_name && $hash->{$column_name} && $hash->{$column_name}->{sum}) {
		push(@ret,
		    Data::Tabular::Cell->new(
			row => $self,
			cell => $column_name,
			colspan => 1, 
			id => $x,
		    ),
		);
	    } else {
		$state++;
	    }
	}
	if ($state == 1) {
	    if ($column_name && $hash->{$column_name} && $hash->{$column_name}->{sum}) {
		push(@ret,
		    Data::Tabular::Cell->new(
			row => $self,
			cell => '_description',
			colspan => $cols - 1, 
			id => $x - ($cols - 1),
		    ),
		); 
		$cols = 1;
		$state++;
	    } else {
		$cols++;
	    }
	}
	if ($state == 2) {
	    if ($column_name && $hash->{$column_name} && $hash->{$column_name}->{sum}) {
	        if ($cols > 1) {
		    push(@ret,
			Data::Tabular::Cell->new(
			    row => $self,
			    cell => '_filler',
			    colspan => $cols - 1, 
			    id => $x,
			),
		    ); 
		    $cols = 1;
		}
		push(@ret,
		    Data::Tabular::Cell->new(
			row => $self,
			cell => $column_name,
			colspan => $cols, 
			id => $x,
		    ),
		); 
		$cols = 1;
	    } else {
	        $cols++;
	    }
	}
	die if ($state >= 3);
	$x++;
    }
    if ($cols > 1) {
	push(@ret,
	    Data::Tabular::Cell->new(
		row => $self,
		cell => '_filler',
		colspan => $cols, 
		id => $x - 1,
	    ),
	); 
	$cols = 1;
    }
die $cols if $cols > 1;
    @ret;
}

sub sum_list
{
    my $self = shift;

    $self->{sum_list};
}

sub get_column
{
    die 'Virtual';
}

sub extra_column
{
    my $self = shift;
    my $row = shift;
    my $key = shift;
die "EXTRA";
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
        die 'only know how to deal with code';
    }
    
    $ret;
}

1;
__END__

