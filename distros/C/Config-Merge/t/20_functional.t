use strict;
use warnings;

use File::Spec;
use Test::More 'tests' => 31;

my $path;
BEGIN {
    my $vol;
    ($vol,$path) = File::Spec->splitpath(
                   File::Spec->rel2abs($0)
            );
    $path = File::Spec->catdir(
        File::Spec->splitdir($path),
        'data','perlmulti'
    );
    $path =  File::Spec->catpath($vol,$path,'');
}

BEGIN { use_ok('Config::Merge', 'My' => $path); }
BEGIN { use_ok('My'); }

is(         C('global.domain'),
            'www.test.com',
            'Func - Simple lookup' );

is_deeply(  scalar C('global.db.hosts.session'),
            [qw(host1 host2 host3)],
            'Func - Array ref lookup' );

is_deeply(  [ C('global.db.hosts.session') ],
            [qw(host1 host2 host3)],
            'Func - Array lookup' );

is(         C('global.db.hosts.image.1'),
            'host5',
            'Func - Array element lookup' );

my @list;
ok(         @list = C('global.testsub'),
            'Func - Retrieve coderef');
is(         scalar @list,
            1,
            'Func - CODE ref list context');

is(         ref $list[0],
            'CODE',
            'Func - CODE ref');

is(         ref scalar C('global.testsub'),
            'CODE',
            'Func - CODE ref scalar context');

ok(         @list = C('global.testregex'),
            'Func - Retrieve regexp');
is(         scalar @list,
            1,
            'Func - Regexp ref list context');

is(         ref $list[0],
            'Regexp',
            'Func - Regexp ref');

is(         ref scalar C('global.testregex'),
            'Regexp',
            'Func - Regexp ref scalar context');

ok(         @list = C('global.testobj'),
            'Func - Retrieve object');
is(         scalar @list,
            1,
            'Func - Object list context');

is(         ref $list[0],
            'ABC',
            'Func - Object ref');

is(         ref scalar C('global.testobj'),
            'ABC',
            'Func - Object scalar context');

is(         C('global.db.hosts.image.1'),
            'host5',
            'Func - Directory lookup' );

is(         defined eval{C('global.db3.hosts.image.1')} ? 1 : 0,
            0,
            'Func - Directory lookup - fail overwritten' );

is(         C('global.db3.different'),
            'data',
            'Func - Directory lookup - succeed overwritten' );

is(         C('global.engine'),
            'Oracle',
            'Func - Local override' );

is(         C('global.db2.hosts.session.0'),
            'local1',
            'Func - Local override deep' );

my $config = My->object();
is(         $config->C('global.domain'),
            'www.test.com',
            'Func - object->C lookup' );

is(         $config->('global.domain'),
            'www.test.com',
            'Func - overload lookup' );

$config->clear_cache();

my $data = C('global.db.hosts');
$data->{session} = '123';
is(         C('global.db.hosts.session'),
            '123',
            'Func - Overwrite original' );

$data = My::clone('global.db.hosts');
$data->{image} = '123';
isnt(       C('global.db.hosts.image'),
            '123',
            'Func - Overwrite clone' );

My::object->load_config();
isnt(       C('global.db.hosts.session'),
            '123',
            'Func - Reload data' );

is          ($config,
             My::object(),
             'Func - reload object same');

$config->clear_cache();
$data = $config->C('global.db.hosts');
$data->{session} = '123';
is(         $config->C('global.db.hosts.session'),
            '123',
            'Func - Object overwrite original' );

$data = $config->clone('global.db.hosts');
$data->{image} = '123';
isnt(       $config->C('global.db.hosts.image'),
            '123',
            'Func - Object overwrite clone' );
