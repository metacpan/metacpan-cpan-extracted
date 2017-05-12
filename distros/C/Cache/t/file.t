#use strict;
use warnings;
use Cache::Tester;
use File::Temp qw(tempdir);
use File::Find;
use Carp;

$SIG{__DIE__} = sub { confess @_; };

BEGIN { plan tests => 2 + $CACHE_TESTS + 3 + 1 }

use_ok('Cache::File');

{
    # Test basic get/set and remove

    my $tempdir = tempdir(CLEANUP => 1);
    my $cache = Cache::File->new(cache_root => $tempdir,
                                 lock_level => Cache::File::LOCK_NFS());
    ok($cache, 'Cache created');

    run_cache_tests($cache);
}

{
    my $tempdir = tempdir(CLEANUP => 1);
    my $cache = Cache::File->new(cache_root => $tempdir,);
    {
        # See:
        # https://rt.cpan.org/Public/Bug/Display.html?id=95608
        my $warning;
        {
            local $SIG{__WARN__} = sub { $warning = shift; };

            $cache->set ('test', {x => 23}, '10 s');
        }
        like ($warning, qr/\AReference passed to set/,
            "Got the right warning on passing a reference to set.")

    }
}

{
    # Test setting of umask
    umask 077;
    my $tempdir = tempdir(CLEANUP => 1);
    my $cache = Cache::File->new(cache_root => $tempdir, cache_umask => 070);
    ok($cache, 'Cache created');


    my $entry = $cache->set('key1', 'data1');
    is($cache->count(), 1, 'Added entry');

    my $valid = 0;

    sub wanted {
        return if $_ eq $tempdir;
        my (undef, undef, $mode) = lstat($_) or die "lstat failed";
        $mode &= 0777;
        (-d and $mode == 0707) or (not -d and $mode == 0606)
            or die 'bad permissions ('.sprintf('%04o', $mode).") on $_";
    }
    eval { File::Find::find({ wanted => \&wanted, no_chdir => 1 }, $tempdir) };
    die if ($@ and $@ !~ /^bad permissions/);
    warn $@ if $@;
    ok((not $@), "Permissions are good");
}
