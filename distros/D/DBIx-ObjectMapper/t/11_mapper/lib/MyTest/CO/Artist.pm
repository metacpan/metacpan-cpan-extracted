package MyTest::CO::Artist;
use strict;
use warnings;

sub new {
    my $class = shift;
    my ( $id, $firstname, $lastname ) = @_;
    bless {
        id        => $id,
        firstname => $firstname,
        lastname  => $lastname,
    }, $class;
}

1;
