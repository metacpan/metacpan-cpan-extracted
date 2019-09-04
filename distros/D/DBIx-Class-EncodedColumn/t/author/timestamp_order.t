use strict;
use warnings;
use Test::More;
use utf8;
use Dir::Self;
use File::Spec;
use File::Temp 'tempdir';
use lib File::Spec->catdir(__DIR__, 'lib');
use DigestTest::Schema;

DigestTest::Schema->load_classes(qw/WithTimeStampChild WithTimeStampChildWrongOrder/);

my $tmp = tempdir( CLEANUP => 1 );
my $db_file = File::Spec->catfile($tmp, 'testdb.sqlite');
my $schema = DigestTest::Schema->connect("dbi:SQLite:dbname=${db_file}");
$schema->deploy({}, File::Spec->catdir(__DIR__, 'var'));

my %create_values = (username => 'testuser', password => 'password1');
my $row = $schema->resultset('WithTimeStampChild')->create( \%create_values );
ok($row->password ne 'password1','password has been encrypted');
ok($row->created,'... and created has been set');
ok(!$row->updated,'... and updated has not been set');
$row->update({username => 'testuser2'});
ok($row->updated,'when updated, updated has now been set');

my $row_wrong = $schema->resultset('WithTimeStampChildWrongOrder')->create( \%create_values );
ok($row_wrong->password eq 'password1','with the wrong order of components password has not been encrypted');

done_testing();
