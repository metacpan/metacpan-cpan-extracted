package MyTest::Basic::ArtistArray;

sub new {
    my $class = shift;
    my ( $lastname, $firstname, $id ) = @_;
    bless {
        id        => $id,
        firstname => $firstname,
        lastname  => $lastname,
    }, $class;
}

sub id {
    my $self = shift;
    if( @_ ) {
        $self->{id} = shift;
    }
    return $self->{id};
}

sub firstname {
    my $self = shift;
    if( @_ ) {
        $self->{firstname} = shift;
    }
    return $self->{firstname};
}

sub lastname {
    my $self = shift;
    if( @_ ) {
        $self->{lastname} = shift;
    }
    return $self->{lastname};
}

1;
