package testlib::Schema;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class::Schema/;
};
__PACKAGE__->load_classes;

1;
