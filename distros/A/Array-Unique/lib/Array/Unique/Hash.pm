package Array::Unique::Hash;

use strict;
use warnings;

our $VERSION = '0.09';

sub new {
    TIEARRAY(@_);
}

sub TIEARRAY {
    my $class = shift;
    my $self = {
		array => [],
		hash => {},
		};
    bless $self, $class;
}


sub CLEAR     { 
    my $self = shift;
    $self->{array} = [];
    $self->{hash} = {};
}

sub EXTEND {
    my $self = shift;
    #?
}

sub STORE {
    my ($self, $index, $value) = @_;
    $self->SPLICE($index, 1, $value);
}



sub FETCHSIZE { 
    my $self = shift;
    return scalar @{$self->{array}};
}

sub FETCH { 
    my ($self, $index) = @_;
    ${$self->{array}}[$index];
}


sub STORESIZE { 
    my $self = shift;
    my $size = shift;

    # We cannot enlarge the array as the values would be undef

    # But we can make it smaller
#   if ($self->FETCHSIZE > $size) {
#	$self->{->Splice($size);
#    }

    $#{$self->{array}} = $size;
    return $size;
}

#sub EXISTS    { exists $_[0]->[$_[1]] }
#sub DELETE    { delete $_[0]->[$_[1]] }
#sub DESTROY

sub SPLICE {
    my $self = shift;
    my $offset = shift;
    my $length = shift;

    # reset length value to positive (this is done by the normal splicetoo)
    if ($length < 0) {
	#$length = @{$self->{array}} + $length;
	$length = $self->FETCHSIZE + $length;
    }

    # reset offset to positive (this is done by the normal splice too)
    if ($offset < 0) {
	$offset += $self->FETCHSIZE;
    }

#    if ($offset > $self->FETCHSIZE) {
#	$offset = $self->FETCHSIZE;
#    }

#    my @s = @{$self->{array}}[$offset..$offset+$length]; # the old values to be returned
    my @original = splice @{$self->{array}}, $offset, $length, @_;

    return @original;
}



sub PUSH {
    my $self = shift;

    $self->SPLICE($self->FETCHSIZE, 0, @_);
#    while (my $value = shift) {
#	$self->STORE($self->FETCHSIZE+1, $value);
#    }
    return $self->FETCHSIZE;
}

sub POP {
    my $self = shift;
    $self->SPLICE(-1);
}

sub SHIFT {
    my $self = shift;

    #($self->{array})[0];
    $self->SPLICE(0,1);
}

sub UNSHIFT {
    my $self = shift;
    $self->SPLICE(0,0,@_);
}

1;
__END__
=pod

 See Array::Unique for documentation

=cut
