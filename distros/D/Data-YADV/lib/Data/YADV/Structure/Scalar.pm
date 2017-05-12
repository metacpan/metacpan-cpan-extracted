package Data::YADV::Structure::Scalar;

use strict;
use warnings;

use base 'Data::YADV::Structure::Base';

sub _get_child_node {
    my ($self, $entry) = @_;

    die "scalar element have no child elements";
}

sub get_size { length $_[0]->get_structure }

1;
