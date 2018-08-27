use strict;
use warnings;

use Test::More;
use Test::Exception;

use App::BorgRestore::Helper;

ok(App::BorgRestore::Helper::untaint_archive_name('abc-1234:5+1') eq 'abc-1234:5+1');
ok(App::BorgRestore::Helper::untaint_archive_name('abc') eq 'abc');
ok(App::BorgRestore::Helper::untaint_archive_name('root-2016-09-30T15+02:00.checkpoint') eq 'root-2016-09-30T15+02:00.checkpoint');

dies_ok(sub{App::BorgRestore::Helper::untaint_archive_name('abc`"\'')}, 'special chars not allowed');
dies_ok(sub{App::BorgRestore::Helper::untaint_archive_name('abc`')}, 'special chars not allowed');
dies_ok(sub{App::BorgRestore::Helper::untaint_archive_name('abc"')}, 'special chars not allowed');
dies_ok(sub{App::BorgRestore::Helper::untaint_archive_name('abc\'')}, 'special chars not allowed');


done_testing;
