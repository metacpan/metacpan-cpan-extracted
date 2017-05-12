package Bar;

sub new {
    my ( $class, $key ) = @_;
    my $self = bless { key => $key }, $class;
    $self->{addr} = "$self";
    return $self;
}
sub package { __PACKAGE__ }

sub hash {
    my $self = shift;
    return $self->{key} unless @_;
    $self->{key} = shift;
    return $self;
}

sub key { 4 }

1;
