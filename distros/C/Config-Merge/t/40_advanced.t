use strict;
use warnings;

use File::Spec;
use Test::More 'tests' => 80;

BEGIN { use_ok('Config::Merge'); }

my ($c,$C);

my $path = get_path('skip');

## SKIP

ok($c = Config::Merge->new(path => $path, skip => qr{skip_\d}),
   'new - skip - regex'
   );
$C=$c->();

ok( exists $C->{skip_not},
   'skip - dir - regex - 1'
   );

ok( ! exists $C->{skip_1},
   'skip - dir - regex - 2'
   );

ok( exists $C->{main}{skip_not},
   'skip - file - regex - 1'
   );

ok(! exists $C->{main}{skip_1},
   'skip - file - regex - 2'
   );

ok($c = Config::Merge->new(path => $path, skip => [qr{skip_1}, qr{skip_2}]),
   'new - skip - regexen'
   );
$C=$c->();

ok( exists $C->{skip_not},
   'skip - dir - regexen - 1'
   );

ok( ! exists $C->{skip_1},
   'skip - dir - regexen - 2'
   );

ok( exists $C->{main}{skip_not},
   'skip - file - regexen - 1'
   );

ok(! exists $C->{main}{skip_1},
   'skip - file - regexen - 2'
   );

ok($c = Config::Merge->new(path => $path, skip => {'skip_1' => 1,'main.skip_1' => 1}),
   'new - skip - hash'
   );
$C=$c->();

ok( exists $C->{skip_not},
   'skip - dir - hash - 1'
   );

ok( ! exists $C->{skip_1},
   'skip - dir - hash - 2'
   );

ok( exists $C->{main}{skip_not},
   'skip - file - hash - 1'
   );

ok(! exists $C->{main}{skip_1},
   'skip - file - hash - 2'
   );

ok($c = Config::Merge->new(path => $path, skip => sub {
     my ($self,$filename) = @_;
     return 1 if $filename=~/skip_1/;
     return 0;
    }),
   'new - skip - sub'
   );
$C=$c->();

ok( exists $C->{skip_not},
   'skip - dir - sub - 1'
   );

ok( ! exists $C->{skip_1},
   'skip - dir - sub - 2'
   );

ok( exists $C->{main}{skip_not},
   'skip - file - sub - 1'
   );

ok(! exists $C->{main}{skip_1},
   'skip - file - sub - 2'
   );

## LOAD_AS for main config
$path = get_path('load_as');

ok($c = Config::Merge->new(path => $path),
   'new - main load_as - none'
   );

is($c->C('file.a'),
   1,
   'main load_as - none - 1'
   );

is($c->C('file-(local).a'),
   4,
   'main load_as - none - 2'
   );

is($c->C('dir.file.a'),
   1,
   'main load_as - none - 3'
   );

is($c->C('dir-(local).file.a'),
   4,
   'main load_as - none - 4'
   );

is($c->C('sub.test.foo'),
   'test',
   'main load_as - none - 5'
   );

is($c->C('sub.test.bar'),
   'test',
   'main load_as - none - 6'
   );

is($c->C('sub.test-(aaa).foo'),
   'test-(aaa)',
   'main load_as - none - 7'
   );

is($c->C('sub.test-(bbb).foo'),
   'test-(bbb)',
   'main load_as - none - 8'
   );

is($c->C('sub.dir.test.foo'),
   'test',
   'main load_as - none - 9'
   );

is($c->C('sub.dir.test.bar'),
   'test',
   'main load_as - none - 10'
   );

is($c->C('sub.dir-(aaa).test.foo'),
   'test-(aaa)',
   'main load_as - none - 11'
   );

is($c->C('sub.dir-(bbb).test.foo'),
   'test-(bbb)',
   'main load_as - none - 12'
   );

ok($c = Config::Merge->new(path => $path, load_as => qr/(.*)-\(local\)/),
   'new - load_as - regex'
   );
$C=$c->();

is($c->C('file.a'),
   '4',
   'load_as - regex - 1'
   );

is($c->C('file.d'),
   '5',
   'load_as - regex - 2'
   );

is($c->C('file.b'),
   '2',
   'load_as - regex - 3'
   );

is($c->C('dir.file.a'),
   '4',
   'load_as - regex - 4'
   );

is($c->C('dir.file.d'),
   '5',
   'load_as - regex - 5'
   );

ok (!exists $C->{dir}{file}{b},
    'load_as - regex - 6'
    );

ok($c = Config::Merge->new(path => $path,
        load_as => sub {
            my ($self,$name) = @_;
            if ($name=~/(.*)-[(](\w+)[)]/) {
                return $2 eq 'aaa' ? $1 : undef;
            }
            return $name;
        }),
   'new - load_as - sub'
   );
$C=$c->();

is($c->C('sub.test.foo'),
   'test-(aaa)',
   'load_as - sub - 1'
   );

is($c->C('sub.test.bar'),
   'test',
   'load_as - sub - 2'
   );

is($c->C('sub.dir.test.foo'),
   'test-(aaa)',
   'load_as - sub - 3'
   );

ok (!exists $C->{sub}{dir}{test}{bar},
   'load_as - sub - 4'
   );

ok (!exists $C->{sub}{'test-(aaa)'},
   'load_as - sub - 5'
   );

ok (!exists $C->{sub}{'test-(bbb)'},
   'load_as - sub - 6'
   );

ok (!exists $C->{sub}{'dir-(aaa)'},
   'load_as - sub - 7'
   );

ok (!exists $C->{sub}{'dir-(bbb)'},
   'load_as - sub - 7'
   );

## SORT
ok($c = Config::Merge->new(path => $path,
        load_as => qr/(.*)-\(local\)/,
        sort => sub {return [sort @{$_[1]}]}),
   'new - load_as - regex'
   );

is($c->C('file.a'),
   '1',
   'sort'
   );

## IS_LOCAL
$path=get_path('local');
ok($c = Config::Merge->new(path => $path),
   'new - is_local - none'
   );

is ($c->C('main.db.servers.server1.host'),
    'host1',
    'is_local - none - 1'
    );

is ($c->C('main.db.servers.list.0'),
    'server1',
    'is_local - none - 2'
    );

ok($c = Config::Merge->new(path => $path, is_local => qr{override}),
   'new - is_local - regex - ..'
   );

is ($c->C('main.db.servers.server1.host'),
    'host4',
    'is_local - regex - .. - 1'
    );

is ($c->C('main.db.servers.list.0'),
    'server3',
    'is_local - regex - .. - 2'
    );

ok($c = Config::Merge->new(path => $path, is_local => {override => 1}),
   'new - is_local - hash - ..'
   );

is ($c->C('main.db.servers.server1.host'),
    'host4',
    'is_local - hash - .. - 1'
    );

is ($c->C('main.db.servers.list.0'),
    'server3',
    'is_local - hash - .. - 2'
    );

ok($c = Config::Merge->new(path => $path, is_local => sub { return $_[1] eq 'override'}),
   'new - is_local - sub - ..'
   );

is ($c->C('main.db.servers.server1.host'),
    'host4',
    'is_local - sub - .. - 1'
    );

is ($c->C('main.db.servers.list.0'),
    'server3',
    'is_local - sub - .. - 2'
    );

ok($c = Config::Merge->new(path => $path,
        is_local => qr{-[(].+[)]},
        load_as  => qr{(.*)-[(].+[)]}),
   'new - is_local - regex - key'
   );

is ($c->C('email.address.sig'),
    'Us',
    'is_local - regex - key - 1'
    );

is ($c->C('email.address.from'),
    'dev@',
    'is_local - regex - key - 2'
    );

is ($c->C('email.address.headers.0'),
    'ddd',
    'is_local - regex - key - 3'
    );

is ($c->C('email.address.subject'),
    'DEV',
    'is_local - regex - key - 4'
    );


ok($c = Config::Merge->new(path => $path,
        is_local => qr{-[(].+[)]},
        load_as  => sub {
            my $name = $_[1];
            if ($name=~/(.*)-[(](.*)[)]/) {
                 return $2 eq 'aaa' ? $1 : undef;
            }
             return $name;}
     ),
   'new - is_local - sub - key'
   );

is ($c->C('email.address.sig'),
    'Us',
    'is_local - sub - key - 1'
    );

is ($c->C('email.address.from'),
    'dev@',
    'is_local - sub - key - 2'
    );

is ($c->C('email.address.headers.0'),
    'ddd',
    'is_local - sub - key - 3'
    );

is ($c->C('email.address.subject'),
    'HELP',
    'is_local - sub - key - 4'
    );

$path = get_path('array');

ok($c = Config::Merge->new(path => $path),
   'new - array merge'
   );

is_deeply(
    scalar $c->C('main.foo'),
    [qw(a b d f h i Z k l m)],
    'array merge - 1'
);

is_deeply(
    scalar $c->C('main.bar'),
    [qw(a b Z d Y f h i j), undef, undef, 'X',undef, 'W'],
    'array merge - 2'
);

is_deeply(
    scalar $c->C('main.baz'),
    [qw(x y z)],
    'array merge - 3'
);


## EXPLAIN
my ($debug, $olderr);
open  $olderr, '>&', \*STDERR or die "Can't dup STDERR: $!";
close STDERR                  or die "Can't close STDERR : $!";
open  STDERR,  '>>', \$debug  or die "Can't open STDERR to debug : $!";

ok($c = Config::Merge->new(path => $path, debug => 1),
   'new - debug'
   );

open  STDERR,  '>&', $olderr  or die "Can't dup OLDERR: $!";
like($debug,
   qr/Entering dir/,
   'debug'
   );

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

1;