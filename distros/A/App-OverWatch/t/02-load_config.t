
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok('App::OverWatch');

my $OverWatch = App::OverWatch->new();

isa_ok($OverWatch, 'App::OverWatch');

lives_ok {
    $OverWatch->load_config_string('
# A comment
db_type = sqlite
user =
password =
dsn = DBI::SQLite:dbname=:memory:
');
    } 'load_config_from_string() lives ok';

throws_ok {
    $OverWatch->load_config_string('
# A comment
user =
password =
dsn = DBI::SQLite:dbname=:memory:
');
    } qr/Error: Require 'db_type'/, 'load_config_from_string() dies ok';

throws_ok {
    $OverWatch->load_config_string(undef);
    } qr/Error: Couldn't load configuration/, 'load_config_from_string(undef) dies ok';

done_testing();

