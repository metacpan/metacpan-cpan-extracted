package Array::Unique::Std;

use strict;
use warnings;

our $VERSION = '0.09';

use Tie::Array;
#use base qw(Tie::StdArray);
our @ISA;
push @ISA, qw(Tie::StdArray);

sub _init {
    my $self = shift;
}

sub clean {
    my $self = shift;

#    print "DEBUG: '@$self'\n";
    my @temp;
    foreach my $v (@$self) {
	next unless (defined $v);
	unless (grep {$v eq $_} @temp) {
	    push @temp, $v;
	}
    }
    @$self = @temp;

}
sub STORESIZE {
    my $self = shift;
    my $size = shift;

    if ($self->FETCHSIZE > $size) {
	$self->SUPER::STORESIZE($size);
    }
}

sub find {
    my $self = shift;
    my $value = shift;
    my @rep = grep {$value eq $self->FETCH($_)} (0 .. $self->FETCHSIZE-1);
    if (@rep) {
	return shift @rep;
    } else {
	return;
    }
}

sub STORE {
    my $self = shift;
    my $index = shift;
    my $value = shift;
#    print "STORE PARAM: @_\n";

    my $existing = $self->find($value); # O(n)
    if (defined $existing) {
#	if ($existing <= $index) {
	    ## nothing to do
#	} else {
	    $self->SUPER::STORE($index, $value);  # value in earlier location
	    $self->SPLICE($existing, 1);
#	}
    } else {
	$self->SUPER::STORE($index, $value);  # new value
    }
    $self->clean;

}

sub PUSH {
    my $self = shift;

    $self->SUPER::PUSH(@_);
    $self->clean;
}


sub UNSHIFT {
    my $self = shift;

    $self->SUPER::UNSHIFT(@_);
    $self->clean;

}

sub SPLICE {
    my $self = shift;

    my @splice = $self->SUPER::SPLICE(@_);
    $self->clean;
    return @splice;
}

1;
__END__
=pod

See documentation in Array::Unique

=cut
