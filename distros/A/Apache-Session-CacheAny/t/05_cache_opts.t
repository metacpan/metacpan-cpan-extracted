use strict;
use Test::More tests => 2;

use Cache::FileCache;
use Apache::Session::CacheAny;

my %session = ();

my $cache_root = './t/cache';
my $ns = rand(time);

tie %session, 'Apache::Session::CacheAny', undef, {
    CacheImpl => 'Cache::FileCache',
    CacheRoot => $cache_root,
    Namespace => $ns,
    DirectoryUmask => 0077,
};
$session{ts} = time;
untie %session;

ok(-d "$cache_root/$ns", 'cache_root');
my $mode = (stat("$cache_root/$ns"))[2];
ok($mode & '0700', 'directory_umask');

Cache::FileCache::Clear($cache_root);
