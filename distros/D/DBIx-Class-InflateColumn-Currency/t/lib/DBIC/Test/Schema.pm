# $Id: /local/DBIx-Class-InflateColumn-Currency/t/lib/DBIC/Test/Schema.pm 1282 2007-02-09T20:58:19.038513Z claco  $
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
