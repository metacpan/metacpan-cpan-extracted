package FooClient;
use Moo;

has 'server' => (
    is  => 'rw'
);


sub search {
    my ( $self, $q ) = @_;

    return $self;
}

sub results {;
    return [
        {
            'person_id' => [1],
        }, 
        {
            'person_id' => [2],
        } 
    ];
}

1;
