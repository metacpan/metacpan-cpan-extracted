package Array::Unique::Quick;

use strict;
use warnings;
use Carp;

our $VERSION = '0.09';

sub _init {
    my $self = shift;

#    $self->[0] = {};
}

sub noimp {
    carp "Method not implemented\n";
}

sub CLEAR     { 
    my $self = shift;
    %$self = ();
}

sub EXTEND {
    my $self = shift;
    #?
}

sub STORE {
    my $self = shift;
    my $index = shift;
    my $value = shift;

    $self->{$value}=1;
}

sub PUSH {
    my $self = shift;

    foreach (@_) {
	$self->{$_}=1;
    }
}

sub FETCHSIZE { 
    my $self = shift;
    return scalar keys %$self;
}

sub FETCH { 
    my ($self, $index) = @_;
    return ((keys (%$self))[$index]);
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


sub SPLICE {
    my $self = shift;
    $self->noimp;
}

sub UNSHIFT {
    my $self = shift;
    $self->noimp;
#    $self->SPLICE(0,0,@_);
}

sub SHIFT {
    my $self = shift;
    $self->noimp;

#    ($self->[0]->Shift)[0];
}

sub POP {
    my $self = shift;
     $self->noimp;
#   ($self->[0]->Pop)[0];
}

1;
__END__
=pod

 See Array::Unique for documentation

=cut
