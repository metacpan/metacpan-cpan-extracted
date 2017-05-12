#!perl
#  Can't use taint switch, 5.6.2 perl's File::Path::rmtree() dies.
##!perl -T

use strict;
use warnings;

use Test::More;

do_my_tests();

#  Have to fudge around so that we don't use the modules until after
#  we've created the faked ones.
sub check_for_modules
{
    foreach my $module ( @_ )
    {
        eval "use $module";
        plan skip_all => "$module required for testing memorycache workaround hack with forced-missing Devel::Size" if $@;
    }
}

sub do_my_tests
{
    plan tests => 6;

    check_for_modules(
        'File::Path qw(rmtree mkpath)',
        'File::Temp qw(mktemp tempdir tempfile)',
        'File::Basename',
        );

    my $fake_dir = setup_fake_modules(
        'Devel::Size' => 0,
        );

    local @INC = @INC;
    @INC = ($fake_dir, @INC);

    check_for_modules(
        'Cache::CacheFactory',
        'Cache::MemoryCache',
        );

    my ( $cache, $key );
    my %vals = (
        '100b' => '1' x 100,
        '900b' => '9' x 900,
        );

    ok( $cache = Cache::CacheFactory->new(
        storage   => 'memory',
        pruning   => { 'size' => { max_size => 500, } },
        ), "construct cache" );

    my $driver = $cache->get_policy_driver( 'pruning', 'size' );
    is( $driver->using_devel_size(), 0, "isn't using Devel::Size." );

    $key = '100b';
    $cache->set(
        key          => $key,
        data         => $vals{ $key },
        );
    is( $cache->get( $key ), $vals{ $key }, "immediate $key fetch" );
    $cache->purge();
    is( $cache->get( $key ), $vals{ $key }, "post-purge $key fetch" );

    $cache->clear();

    $key = '900b';
    $cache->set(
        key          => $key,
        data         => $vals{ $key },
        );
    is( $cache->get( $key ), $vals{ $key }, "immediate $key fetch" );
    $cache->purge();
    is( $cache->get( $key ), undef, "post-purge $key fetch" );

    $cache->clear();
}

#  All functions below cribbed from Test::CPANpm::Fake.pm,
#  credit to Tyler MacDonald.
sub make_fake_module {
    my($lib, $package, $good) = @_;
    
    $good = $good ? 1 : 0;
    my $pathname = "$lib/$package.pm";
    $pathname =~ s{::}{/}g;
    my $dir = dirname($pathname);
    mkpath($dir);
    open(my $fh, ">$pathname") or die "write $pathname: $!";
    print $fh "$good;\n";
    close $fh;
    
    return $pathname;
}

sub setup_fake_modules {
    my %modules = @_;
    
    my $fake_dir = tempdir( 'cache-cachefactory-XXXXXXXXXX',
        CLEANUP => 1,
        TMPDIR  => 1 );
    
    while(my($k, $v) = each(%modules)) {
        make_fake_module($fake_dir, $k, $v);
    }

    return $fake_dir;
}
