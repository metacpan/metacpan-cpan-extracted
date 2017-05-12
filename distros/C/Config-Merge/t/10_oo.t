use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use File::Spec;
use Test::More 'tests' => 30;

BEGIN { use_ok('Config::Merge'); }

my $config;
ok(         $config = Config::Merge->new( get_path('empty') ),
            'OO - Load empty dir' );

ok(         $config = Config::Merge->new( get_path('perl') ),
            'OO - Load perl dir' );

is(         $config->C('global.domain'),
            'www.test.com',
            'OO - Simple lookup' );

is(         $config->('global.domain'),
            'www.test.com',
            'OO - Overload lookup' );

is_deeply(  scalar $config->C('global.db.hosts.session'),
            [qw(host1 host2 host3)],
            'OO - Array ref lookup' );

is_deeply(  [ $config->C('global.db.hosts.session') ],
            [qw(host1 host2 host3)],
            'OO - Array lookup' );

is(         $config->C('global.db.hosts.image.1'),
            'host5',
            'OO - Array element lookup' );

ok(         $config = Config::Merge->new( get_path('perlmulti') ),
            'OO - Load perl dir' );

my @list;
ok(         @list = $config->C('global.testsub'),
            'OO - Retrieve code');
is(         scalar @list,
            1,
            'OO - CODE ref list context');

is(         ref $list[0],
            'CODE',
            'OO - CODE ref');

is(         ref scalar $config->C('global.testsub'),
            'CODE',
            'OO - CODE ref scalar context');

ok(         @list = $config->C('global.testregex'),
            'OO - Retrieve regepx');
is(         scalar @list,
            1,
            'OO - Regexp ref list context');

is(         ref $list[0],
            'Regexp',
            'OO - Regexp ref');

is(         ref scalar $config->C('global.testregex'),
            'Regexp',
            'OO - Regexp ref scalar context');

ok(         @list = $config->C('global.testobj'),
            'OO - Retrieve object');
is(         scalar @list,
            1,
            'OO - Object list context');

is(         ref $list[0],
            'ABC',
            'OO - Object ref');

is(         ref scalar $config->C('global.testobj'),
            'ABC',
            'OO - Object scalar context');

is(         $config->C('global.db.hosts.image.1'),
            'host5',
            'OO - Directory lookup' );

is(         $config->C('global.db.hosts.image.1'),
            'host5',
            'OO - Directory lookup' );

is(         defined eval{$config->C('global.db3.hosts.image.1')} ? 1 : 0,
            0,
            'OO - Directory lookup - fail overwritten' );

is(         $config->C('global.db3.different'),
            'data',
            'OO - Directory lookup - succeed overwritten' );

is(         $config->C('global.engine'),
            'Oracle',
            'OO - Local override' );

is(         $config->C('global.db2.hosts.session.0'),
            'local1',
            'OO - Local override deep' );

$config->clear_cache();
my $data = $config->C('global.db.hosts');
$data->{session} = '123';
is(         $config->C('global.db.hosts.session'),
            '123',
            'OO - Overwrite original' );

$data = $config->clone('global.db.hosts');
$data->{image} = '123';
isnt(       $config->C('global.db.hosts.image'),
            '123',
            'OO - Overwrite clone' );

$config->load_config();
isnt(       $config->C('global.db.hosts.session'),
            '123',
            'OO - Reload data' );


#===================================
sub get_path {
#===================================
    my ($vol,$path) = File::Spec->splitpath(
                   File::Spec->rel2abs($0)
            );
    $path = File::Spec->catdir(
        File::Spec->splitdir($path),
        'data',@_
    );
    return File::Spec->catpath($vol,$path,'');
}
