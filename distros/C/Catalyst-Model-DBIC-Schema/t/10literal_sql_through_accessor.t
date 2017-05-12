use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib";
use File::Spec::Functions 'catfile';
use DBI;

my $test_dir = $FindBin::Bin;
my $db       = catfile($test_dir, 'testdb.db');

my $dbh = DBI->connect("dbi:SQLite:$db", '', '', {
    RaiseError => 1, PrintError => 0
});

$dbh->do(<<'EOF');
create table users (
    id integer primary key,
    first_name varchar(100),
    middle_name varchar(100),
    last_name varchar(100),
    email_address varchar(100)
)
EOF
$dbh->disconnect;

my $model = instance();
my $rs    = $model->resultset('User');

my $row = $rs->create({ first_name => 'Foo', last_name => 'Bar' });

$row->first_name(\['last_name']);

lives_ok {
    $row->update;
} 'update survived';

$row->discard_changes;

is $row->first_name, 'Bar',
    'row updated with literal SQL through accessor';

done_testing;

sub instance {
    MyApp::Model::DB->COMPONENT('MyApp', {
        schema_class => 'ASchemaClass',
        connect_info => ["dbi:SQLite:$db", '', ''],
        @_,
    })
}

{
    package MyApp;
    use Catalyst;
}
{
    package MyApp::Model::DB;
    use base 'Catalyst::Model::DBIC::Schema';
}

END {
    $model->storage->disconnect if $model;
    unlink $db or die "Could not delete $db: $!";
}
