



package DataCube::Pathwalker;

sub new {
    my($class,%opts) = @_;
    my $lattice = $opts{lattice};
    my $state   = [map{0}(0..$#$lattice)];
    return bless {%opts, state => $state}, ref($class) || $class;
}

sub reset {
    my($self,%opts) = @_;
    $self->{state}  = [map{0}(0..$#{$self->{lattice}})];
    return undef;
}

sub next_path {
    my($self,%opts) = @_;
    my $path    = [];
    my $state   = $self->{state};
    my $lattice = $self->{lattice};
    for(my $i = $#$state; $i > 0; $i--){
        if($state->[$i] > $#{$lattice->[$i]}){
            $state->[$i] = 0;
            $state->[$i-1]++;
        }
    }
    return $self->reset if $state->[0] > $#{$lattice->[0]};
    for my $i(0..$#$state){
        $path->[$i] = $lattice->[$i][$state->[$i]];
    }
    $state->[$#$state]++;
    return $path;
}

sub state {
    my($self) = @_;
    return $self->{state};
}



1;



