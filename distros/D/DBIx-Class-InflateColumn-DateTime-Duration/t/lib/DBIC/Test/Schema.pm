package DBIC::Test::Schema;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class::Schema/;
};
__PACKAGE__->load_classes;

sub dsn {
    return shift->storage->connect_info->[0];
};

1;
