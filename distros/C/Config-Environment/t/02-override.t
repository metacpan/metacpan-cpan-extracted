BEGIN {
    $ENV{MYAPP_DB_1_USER} = 'admin';
    $ENV{MYAPP_DB_1_PASS} = 's3cret';
    $ENV{MYAPP_DB_1_HOST} = 'localhost';
}

use utf8;
use strict;
use warnings;
use Test::More;
use Config::Environment;

my $conf = Config::Environment->new(domain => 'myapp', override => 0);
my $conn = $conf->param('db.1.conn' => 'dbi:mysql:dbname=foobar');
my $user = $conf->param('db.1.user' => 'user');
my $pass = $conf->param('db.1.pass' => 'xpl0!+');
my $host = $conf->param('db.1.host');

is $user, 'admin',     '$user is ok - no overriding';
is $pass, 's3cret',    '$pass is ok - no overriding';
is $host, 'localhost', '$host is ok - no overriding';
is $conn, 'dbi:mysql:dbname=foobar', '$conn is ok';

my $db = $conf->param('db' => {1=>{port=>8000}});
ok exists $db->{1}, '$db is ok - returned from param()';

$host = $conf->param('db.1.host');
is $host, 'localhost', '$host is ok - no overriding, persisted';

$host = $conf->param('db')->{1}{host};
is $host, 'localhost', '$host is ok - no overriding, persisted';

$conf = Config::Environment->new(domain => 'myapp');
$user = $conf->param('db.1.user' => 'user');
$pass = $conf->param('db.1.pass' => 'xpl0!+');
$host = $conf->param('db.1.host');

is $user, 'user',      '$user is ok - overridden';
is $pass, 'xpl0!+',    '$pass is ok - overridden';
is $host, 'localhost', '$host is ok - available';

$db = $conf->param('db' => {1=>{port=>8000}});
ok exists $db->{1}, '$db is ok - returned from param()';

$host = $conf->param('db.1.host');
is $host, 'localhost', '$host is ok - persisted';

$host = $conf->param('db')->{1}{host};
is $host, 'localhost', '$host is ok - no overriding, persisted';

done_testing;
