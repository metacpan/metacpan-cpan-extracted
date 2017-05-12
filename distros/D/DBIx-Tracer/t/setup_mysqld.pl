use JSON;
use t::Util;
my $mysqld = t::Util->setup_mysqld or die;
$ENV{__TEST_DBIxTracer} = encode_json { %$mysqld } if $mysqld;
$|++;
print "export __TEST_DBIxTracer='$ENV{__TEST_DBIxTracer}'\n";
sleep 500;
print "fin.\n";
