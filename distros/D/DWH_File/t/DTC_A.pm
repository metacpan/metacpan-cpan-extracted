package DTC_A;

# Test class for testing DWH_File object-data handling

sub new {
    my ( $this, $string ) = @_;
    my $class = ref $this || $this;
    my @chars = split '', $string;
    my %popul = ();
    for ( @chars ) { $popul{ $_ }++ }
    my $self = { arfgab => join( '', reverse @chars ),
		 popul => \%popul,
	     };
    bless $self, $class;
    return $self;
}

sub arfgab {
    return $_[ 0 ]->{ arfgab };
}

sub frequency {
    my ( $self, $chars ) = @_;
    my %chars = ();
    @chars{ split '', $chars } = ();
    my $sum = 0;
    my %cop = %{ $self->{ popul } };
    for ( keys %chars ) { $sum += $cop{ $_ } || 0 }
    return $sum;
}

1;

