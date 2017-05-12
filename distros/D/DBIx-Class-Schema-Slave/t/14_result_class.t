use strict;
use warnings;

use Test::More;
use lib qw( t/lib );
use DBICTest;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 6 );
}

my $schema = DBICTest->init_schema;
my $prefix = 'DBICTest::';
my %m_moniker = (artist=>'Artist',cd =>'CD',track=>'Track');

## master
while(my($table,$moniker) = each %m_moniker) {
    my $result_class = $schema->resultset($moniker)->result_class;
    is($result_class,$prefix.$moniker,"master $table \"result_class\"");
}

## slave
while(my($table,$moniker) = each %m_moniker) {
    my $result_class = $schema->resultset($moniker)->result_class;
    is($result_class,$prefix.$moniker,"slave $table \"result_class\"");
}
