package Algorithm::CP::IZ::ValueSelector;

use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

use Algorithm::CP::IZ;

sub new {
    my $class = shift;
    my $iz = shift;
    my $something = shift;
    
    my $self;
    
    if (looks_like_number($something)) {
	return Algorithm::CP::IZ::ValueSelector::IZ->new($iz, int($something));
    }
    else {
	return Algorithm::CP::IZ::ValueSelector::UD->new($iz, $something);
    }
}

#
# ValueSelector probided by iZ
#
package Algorithm::CP::IZ::ValueSelector::IZ;

use base qw(Algorithm::CP::IZ::ValueSelector);

sub new {
    my $class = shift;
    my ($iz, $id) = @_;

    my $vs = Algorithm::CP::IZ::cs_getValueSelector($id);

    my $self = {
	_iz => $iz,
	_vs => $vs,
    };
    
    bless $self, $class;
}

sub init {
    my $self = shift;
    my ($index, $var_array) = @_;

    my $iz = $self->{_iz};
    my $vs = $self->{_vs};
    my $size = scalar @$var_array;
    
    @$var_array = map { ref $_ ? $_ : $iz->_const_var(int($_)) } @$var_array;

    my $array = $iz->_create_registered_var_array($var_array);
    return unless ($array);

    return Algorithm::CP::IZ::ValueSelector::Bound::IZ->new($vs, $index,
							    $array, $size);
}

sub prepare {
}

#
# ValueSelector bound to variable
#
package Algorithm::CP::IZ::ValueSelector::Bound::IZ;

sub new {
    my $class = shift;
    my ($vs, $index, $array, $size) = @_;
    
    my $ptr = Algorithm::CP::IZ::valueSelector_init($vs, $index,
						    $$array, $size);

    my $self = {
	_vs => $vs,
	_ptr => $ptr,
	_index => $index,
	_array => $array,
	_size => $size,
    };

    bless $self, $class;
}

sub next {
    my $self = shift;
    
    my $vs = $self->{_vs};
    my $index = $self->{_index};
    my $array = $self->{_array};
    my $ptr = $self->{_ptr};
    my $size = $self->{_size};
    
    return Algorithm::CP::IZ::cs_selectNextValue($vs, $index, $$array, $size, $ptr);
}

# end is bound to DESTORY in Perl way
sub DESTROY {
    my $self = shift;

    my $vs = $self->{_vs};
    my $index = $self->{_index};
    my $array = $self->{_array};
    my $ptr = $self->{_ptr};
    my $size = $self->{_size};

    Algorithm::CP::IZ::cs_endValueSelector($vs, $index, $$array, $size, $ptr);
}

#
# ValueSelector user defined (simple)
#
# init : $cls->new(Int_instance) is called. Instance of $cls must be returned.
# next : $obj->next(Int_instane) is called.
# end : $obj is released.
#
# Callback functions don't take class parameter therefore useer defined
# value selectors distincted by its index (when search function is called).
#
package Algorithm::CP::IZ::ValueSelector::Simple;

use base qw(Algorithm::CP::IZ::ValueSelector);

sub new {
    my $class = shift;
    my ($iz, $cls) = @_;

    my $vs = Algorithm::CP::IZ::createSimpleValueSelector();

    my $self = {
	_iz => $iz,
	_vs => $vs,
	_cls => $cls,
    };

    bless $self, $class;
}

sub prepare {
    my $self = shift;
    my ($index) = @_;

    # keep init in memory to avoid GC
    # but don't keep $self too avoid cyclic reference
    my $cls = $self->{_cls};

    $self->{_init} = sub {
	return $cls->new(@_);
    };

    return Algorithm::CP::IZ::registerSimpleValueSelectorClass($index, $self->{_init});
}

sub init {
    my $self = shift;
    my ($index, $var_array) = @_;

    $self->prepare($index);
    
    my $iz = $self->{_iz};
    my $vs = $self->{_vs};
    my $size = scalar @$var_array;
    
    @$var_array = map { ref $_ ? $_ : $iz->_const_var(int($_)) } @$var_array;

    my $array = $iz->_create_registered_var_array($var_array);
    return unless ($array);

    return Algorithm::CP::IZ::ValueSelector::Bound::IZ->new($vs, $index,
							    $array, $size);
}

sub DESTROY {
    Algorithm::CP::IZ::deleteSimpleValueSelector();
}


1;

