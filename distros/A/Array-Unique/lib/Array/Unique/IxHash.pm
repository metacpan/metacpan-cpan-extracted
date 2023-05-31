package Array::Unique::IxHash;
# This implementation uses Tie::IxHash

use strict;
use warnings;

our $VERSION = '0.09';

use Tie::IxHash;

sub _init {
    my $self = shift;

    $self->[0] = Tie::IxHash->new();
}

sub CLEAR     { 
    my $self = shift;
    $self->[0]->Splice(0);
}

sub EXTEND {
    my $self = shift;
    #?
}

sub STORE {
    my ($self, $index, $value) = @_;
    $self->SPLICE($index, 1, $value);
}

sub PUSH {
    my $self = shift;

    while (my $value = shift) {
	$self->[0]->Push($value => 1);
    }
}

sub FETCHSIZE { 
    my $self = shift;
    return $self->[0]->Length;
}

sub FETCH { 
    my ($self, $index) = @_;
    $self->[0]->Keys($index);
}


sub STORESIZE { 
    my $self = shift;
    my $size = shift;

    # We cannot enlarge the array as the values would be undef

    # But we can make it smaller
    if ($self->FETCHSIZE > $size) {
	$self->[0]->Splice($size);
    }
}

#sub EXISTS    { exists $_[0]->[$_[1]] }
#sub DELETE    { delete $_[0]->[$_[1]] }
#sub DESTROY

# insert one value at the given position
# but if the value already existed then set its
# postion to the lower place between its original position
# and the new one.
sub insert {
    my ($self, $index, $value) = @_;

    #$self->[0]->Replace($index, 1, $value);  
    # Replace does not keep the order when storing an existing value
    # in an index higher than its original index.

    if ($self->FETCHSIZE < $index+1) {
	$self->[0]->Push($value => 1);
    } else {
	my $oldindex = $self->[0]->Indices($value);
	if (not defined $oldindex) {
	    $self->[0]->Splice($index, 0 , $value);
	} else {
	    if ($oldindex == $index) {
		$self->[0]->Splice($index, 1, $value => 1);
	    } elsif ($oldindex > $index) {
		$self->[0]->Splice($oldindex, 1);
		$self->[0]->Splice($index, 0, $value);
	    } else {
		# nothing to do
	    }
	}
    }

}

sub SPLICE {
    my $self = shift;
    my $offset = shift;
    my $length = shift;

    if ($offset < 0) {
	$offset += $self->FETCHSIZE;
    }
    my @s = $self->[0]->Splice($offset, $length);

    foreach my $v (reverse @_) {
	$self->insert($offset, $v);
    }

    my @q;
    for my $i (1..scalar(@s)/2) {
	push @q, $s[2*$i-2];
    }
    return @q;
}

sub UNSHIFT {
    my $self = shift;
    $self->SPLICE(0,0,@_);
}

sub SHIFT {
    my $self = shift;

    ($self->[0]->Shift)[0];
}

sub POP {
    my $self = shift;
    ($self->[0]->Pop)[0];
}

1;
__END__
=pod

 See Array::Unique for documentation

=cut
