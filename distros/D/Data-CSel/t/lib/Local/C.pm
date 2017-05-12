package # hide from PAUSE
    Local::C;

sub new {
    my $class = shift;
    my %attrs = @_;
    bless \%attrs, $class;
}

sub attr1 {
    my $self = shift;
    $self->{attr1} = $_[0] if @_;
    $self->{attr1};
}

1;
