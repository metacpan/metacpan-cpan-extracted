package AI::Fuzzy::Axis;

use AI::Fuzzy::Label;
## Container for Fuzzy Labels #### 

sub new {

    my ($class) = @_;
    my $self = {};

    $self->{labels} = {};

    bless $self, $class;
    return $self;
}

sub addlabel {
    # adds a label for a range of values..
    my ($self, $label, $low, $mid, $high) = @_;

    if ($label->can("name") ) {
	$self->{labels}->{$label->name} = $label;
    } else {
	$self->{labels}->{$label} = new AI::Fuzzy::Label($label, $low, $mid, $high);
    }

    return $self->{labels}->{$label};
}


sub applicability {
    # this function should be called something else..
    # calculates to what degree $label applies to a $value

    my ($self, $value, $label) = @_;
    my $membership = 0;

    return $label->applicability($value) if ($label->can("applicability"));
    return undef unless ( exists $self->{labels}->{$label} );
    return $self->{labels}->{$label}->applicability($value);
}

sub label {
    # returns a label associated with this text
    my ($self, $name) = @_;

    return $self->{labels}->{$name};
}

sub labelvalue {
    # returns a label associated with this value
    my ($self, $value) = @_;
    my $label;
    my %weight;
    my $total_weight = 0;
    my @range = $self->range();


    # first, find out the applicability of each label
    # and weight the labels accordingly.
    foreach $label (@range) {
        my $labelname ;
	my $w;

	if ($label->can("name")) {
	    $labelname = $label->name;
	    $w = $label->applicability($value);
	} else {
	    $labelname = $label;
	    $w = $self->applicability($value, $label);
	}

	next unless $w > 0;

	$weight{$labelname} = $w;
	$total_weight += $weight{$labelname};
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
	return $self->{labels}->{$label} if $x >= $v;
    }  

    # and if none of that worked..

    return 0;
}


sub range {
    # returns a list of sorted labels
    my ($self) = @_;
    my $l = $self->{labels};
    return sort { $a <=> $b } values %{$l};
}

sub lessthan {
    my ($self, $labela, $labelb) = @_;

    if ( exists $self->{labels}->{$labela} and exists $self->{labels}->{$labelb} ) {
	my $la = $self->{labels}->{$labela};
	my $lb = $self->{labels}->{$labelb};

	return $la->lessthan($lb);

    } else {
	return undef;
    }
}
sub lessequal {
    my ($self, $labela, $labelb) = @_;

    if ( exists $self->{labels}->{$labela} and exists $self->{labels}->{$labelb} ) {
	my $la = $self->{labels}->{$labela};
	my $lb = $self->{labels}->{$labelb};
	
	return $la->lessequal($lb);
    } else {
	return undef;
    }
}

sub greaterthan {
    my ($self, $labela, $labelb) = @_;

    if ( exists $self->{labels}->{$labela} and exists $self->{labels}->{$labelb} ) {
	my $la = $self->{labels}->{$labela};
	my $lb = $self->{labels}->{$labelb};
	
	return $la->greaterthan($lb);
    } else {
	return undef;
    }
}
sub greaterequal {
    my ($self, $labela, $labelb) = @_;

    if ( exists $self->{labels}->{$labela} and exists $self->{labels}->{$labelb} ) {
	my $la = $self->{labels}->{$labela};
	my $lb = $self->{labels}->{$labelb};
	
	return $la->greaterequal($lb);
    } else {
	return undef;
    }
}

sub between {
    my ($self, $labela, $labelb, $labelc) = @_;

    if ( exists $self->{labels}->{$labela} and exists $self->{labels}->{$labelb} 
         and exists $self->{labels}->{$labelc} ) {
	my $la = $self->{labels}->{$labela};
	my $lb = $self->{labels}->{$labelb};
	my $lc = $self->{labels}->{$labelc};
	
	return $la->between($lb, $lc);
    } else {
	return undef;
    }
}
1;
