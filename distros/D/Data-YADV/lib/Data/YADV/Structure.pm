package Data::YADV::Structure;

use strict;
use warnings;

use Data::YADV::Structure::Array;
use Data::YADV::Structure::Hash;
use Data::YADV::Structure::Scalar;

sub new {
    my ($class, $structure, $path, $parent) = @_;

    my $type = ucfirst(lc(ref($structure) || 'Scalar'));
    "Data::YADV::Structure::$type"->new($structure, $path, $parent);
}

1;
