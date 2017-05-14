package AI::Fuzzy::Set;

## Fuzzy Set ####

sub new { 

    my $class = shift;
    my $self = {} ;

    # accepts a hash of member weights..
    # ( $members{$member}=$weight )

    %{$self->{members}} = @_;
    bless $self, $class;
}

sub membership {
    # naturally, it returns a fuzzy value - the degree
    # to wich $item is a member of the set! :)

    my $self = shift;
    my $item = shift;

    if (defined(${$self->{members}}{$item})) {
	return ${$self->{members}}{$item};
    } else {
	return 0;
    }
}

sub members {
    # returns list of members, sorted from least membership to greatest
    my $self = shift;

    my %l = %{$self->{members}};
    return sort { $l{$a} <=> $l{$b} } keys %l;
}

sub equal {
    # returns true if the argument set is equal to this one
    my $self = shift;
    my $otherset = shift;

    my (%us, %them);
    %us = %{$self->{members}} if (exists $self->{members});
    %them = %{$otherset->{members}} if (exists $otherset->{members});

    # for all keys in us and them
    foreach my $key (keys (%us), keys (%them)) {
	# not equal if either set is missing a key
	return 0 unless (exists ($us{$key}) && exists ($them{$key}) );

	# not equal if the membership of the keys isn't equal
	return 0 unless (float_equal($us{$key},$them{$key}, 10));
    }

    # otherwise they are equal
    return 1;
}

sub union {
    # returns a set that is the union of us and the argument set
    my $self = shift;
    my $otherset = shift;

    my (%us, %them, %new);
    %us = %{$self->{members}} if (exists $self->{members});
    %them = %{$otherset->{members}} if (exists $otherset->{members});

    # for all keys in us and them
    foreach my $key (keys (%us), keys (%them)) {
	if (not exists $us{$key} and exists $them{$key}) {
	    $new{$key} = $them{$key};
	    next;
	}
	if (not exists $them{$key} and exists $us{$key}) {
	    $new{$key} = $us{$key};
	    next;
	}
	if ($us{$key} >= $them{$key}) {
	    $new{$key} = $us{$key};
	} else {
	    $new{$key} = $them{$key};
	}
    }

    return new AI::Fuzzy::Set(%new);
}

sub intersection {
    # returns a set that is the intersection of us and the argument set
    my $self = shift;
    my $otherset = shift;

    my (%us, %them, %new);
    %us = %{$self->{members}} if (exists $self->{members});
    %them = %{$otherset->{members}} if (exists $otherset->{members});

    # for all keys in us and them
    foreach my $key (keys (%us), keys (%them)) {
	if (not exists $us{$key} or not exists $them{$key}) {
	    $new{$key} = 0;
	    next;
	}
	if ($us{$key} <= $them{$key}) {
	    $new{$key} = $us{$key};
	} else {
	    $new{$key} = $them{$key};
	}
    }

    return new AI::Fuzzy::Set(%new);
}

sub complement {
    # returns a set that is the complement of us
    # requires that the set contain values from 0 to 1
    my $self = shift;

    my (%new);

    foreach my $member ($self->members) {
	my $comp = 1 - $self->membership($member); 
	return undef if ($comp < 0 || $comp >1);

	$new{$member} = $comp;
    }

    return new AI::Fuzzy::Set(%new);
}

sub support {
    # returns the support set.
    # defined as the set of all elements in our set with a non-zero membership.
    my $self = shift;

    my (%support);
    foreach my $member ($self->members) {
	$support{$member}++ if ($self->membership($member) != 0);
    }

    return new AI::Fuzzy::Set(%support);
}

sub core { 
    # returns the core set.
    # defined as the set of all elements in our set with full membership
    my $self = shift;

    my (%core);
    foreach my $member ($self->members) {
	$core{$member}++ if ($self->membership($member) == 1);
    }

    return new AI::Fuzzy::Set(%core);
}

sub height { 
    # returns the height of the set
    # defined as the maximal membership value in our set
    my $self = shift;

    my ($max) = 0;
    foreach my $member ($self->members) {
	$max = $self->membership($member) if ($self->membership($member) > $max);
    }

    return $max;
}

sub is_normal {
    # Logical return
    # normal is defined as a set with a height of 1
    my $self = shift;

    return 1 if ($self->height == 1);
    return 0;
}

sub is_subnormal {
    # Logical return
    # normal is defined as a set with a height less than 1
    my $self = shift;

    return 1 if ($self->height < 1);
    return 0;
}

sub as_string {
    my $self = shift;

    my @members;
    foreach my $member ($self->members) {
	push (@members, "$member/" . $self->membership($member) );
    }

    return join(', ', @members);
}

sub float_equal {
    my ($A, $B, $dp) = @_;

#    print  sprintf("%.${dp}g", $A). " eq " . sprintf("%.${dp}g", $B) . "\n";
    return sprintf("%.${dp}g", $A) eq sprintf("%.${dp}g", $B);
}

1;

