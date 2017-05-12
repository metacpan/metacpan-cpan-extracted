package AI::Fuzzy::Label;

## Fuzzy Label #### 

sub new {

    my ($class) = @_;
    my $self = {};

    $self->{labels} = {};

    bless $self, $class;
    return $self;
}

sub addlabel {

    # adds a label for a range of values..

    my ($self, $name, $low, $mid, $high) = @_;

    $self->{labels}->{$name}->{low}  = $low;
    $self->{labels}->{$name}->{mid}  = $mid;
    $self->{labels}->{$name}->{high} = $high;

    return 1;
}

sub applicability {

    # this function should be called something else..
    # calculates to what degree $label applies to a $value

    my ($self, $value, $label) = @_;
    my $membership = 0;

    $label = $self->{labels}->{$label};

    # m = slope of the line.. (change in y/change in x) 
    #     change in y is 1 as membership increases, -1 as it decreases

    my $mIncreasing =  1 / ($label->{mid} - $label->{low});
    my $mDecreasing = -1 / ($label->{high} - $label->{mid});

    # reject values that are "out of bounds"

    return ($membership = 0)
	if ($value <= $label->{low} ) or ($value >= $label->{high} );

    # now calculate membership:
    # y=mx+b , just like in algebra

    if ($value < $label->{mid}) {
	$membership = ($value - $label->{low}) * $mIncreasing;
    } elsif ($value == $label->{mid}) {
        $membership = 1;
    } else {
	$membership = (($value - $label->{mid}) * $mDecreasing) + 1;
    }
    
    return $membership;
}

sub label {

    my ($self, $value) = @_;

    my $label;
    my %weight;
    my $total_weight = 0;
    my @range = $self->range();

    # first, find out the applicability of each label
    # and weight the labels accordingly.

    foreach $label (@range) {
	my $w = $self->applicability($value, $label);
	next unless $w > 0;

	$weight{$label} = $w;
	$total_weight += $weight{$label};
    }

    # in list context, just return the weights
    if (wantarray) {
	return %weight;
    }

    # give up if no labels apply
    return 0 unless $total_weight > 0;

    # otherwise, use those weights as probabilities
    # and randomly pick a label:

    my $v = rand $total_weight;
    my $x = 0;

    # it doesn't matter how %weight is sorted..
    foreach $label (keys %weight) {
	$x += $weight{$label};
	return $label if $x >= $v;
    }  

    # and if none of that worked..

    return 0;
}


sub range {
    # returns a list of labels, sorted by their midpoints
    my ($self) = @_;
    my $l = $self->{labels};
    return sort { $l->{$a}->{mid} <=> $l->{$b}->{mid} } keys %{$l};
}

1;




