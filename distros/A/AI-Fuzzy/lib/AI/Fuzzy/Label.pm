package AI::Fuzzy::Label;

## Fuzzy Label #### 
use overload (	'>'  => \&greaterthan,
		'<'  => \&lessthan,
		'>=' => \&greaterequal,
		'<=' => \&lessequal,
		'<=>'=> \&spaceship,
		'""'  => \&stringify 
	    );

sub new {
    my ($class, $name, $low, $mid, $high) = @_;
    my $self = {};

    bless $self, $class;

    $self->{name} = $name;
    $self->{low}  = $low;
    $self->{mid}  = $mid;
    $self->{high} = $high;

    return $self;
}

sub name {
    my ($self, $name) = @_;

    $self->{name} = $name if ($name);
    return $self->{name};
}

sub stringify {
    my $self=shift;
    return qq([$self->{name}: $self->{low},$self->{mid},$self->{high}]); 
}

sub lessthan {
    my ($self, $that) = @_;

    if ($self->{low} < $that->{low}) {
	return 1;
    } else {
	return 0;
    }
}

sub lessequal {
    my ($self, $that) = @_;

    if ($self->{low} <= $that->{low}) {
	return 1;
    } else {
	return 0;
    }
}

sub greaterthan {
    my ($self, $that) = @_;

    if ($self->{high} > $that->{high}) {
	return 1;
    } else {
	return 0;
    }
}

sub greaterequal {
    my ($self, $that) = @_;

    if ($self->{high} >= $that->{high}) {
	return 1;
    } else {
	return 0;
    }
}

sub between {
    my ($self, $that1, $that2) = @_;

    if ( ( $that1 <= $self and $self <= $that2) ||
	 ( $that2 <= $self and $self <= $that1) ) {
	return 1;
    } else {
	return 0;
    }
}

sub spaceship {
    my ($self, $that) = @_;

    return  ( $self->{mid} <=> $that->{mid} );
}

sub applicability {
    # this function should be called something else..
    # calculates to what degree this label applies to a $value

    my ($self, $value) = @_;
    my $membership = 0;

    # if the low and mid points are same as value, full membership
    # same if mid and high are same as value
    if ($self->{mid} == $self->{low} && $value == $self->{low}) { return 1 };  
    if ($self->{high} == $self->{mid} && $value == $self->{high}) { return 1 };  

    # m = slope of the line.. (change in y/change in x) 
    #     change in y is 1 as membership increases, -1 as it decreases
    my $mIncreasing =  1 / ($self->{mid} - $self->{low});
    my $mDecreasing = -1 / ($self->{high} - $self->{mid});

    # reject values that are "out of bounds"
    return ($membership = 0)
	if ($value <= $self->{low} ) or ($value >= $self->{high} );

    # now calculate membership:
    # y=mx+b , just like in algebra
    if ($value < $self->{mid}) {
	$membership = ($value - $self->{low}) * $mIncreasing;
    } elsif ($value == $self->{mid}) {
        $membership = 1;
    } else {
	$membership = (($value - $self->{mid}) * $mDecreasing) + 1;
    }
    
    return $membership;
}

sub range {
    # returns the distance from one endpoint to the other
    
    my ($self) = @_;
    return abs( $self->{high} - $self->{low} );
}

1;
