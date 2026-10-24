use strict;
use warnings;
use Test::Most;

use File::Spec;
use File::Temp qw(tempdir);
use Time::HiRes ();

use App::FileSync qw(set_mtime);

my $dir  = tempdir(CLEANUP => 1);
my $file = File::Spec->catfile($dir, 'mtime.txt');
open my $fh, '>', $file or die "Cannot write $file: $!";
close $fh;

# Some Windows builds ship a Time::HiRes whose utime croaks as unimplemented.
# Pretend to be one of them: the builtin fallback must still set the time.
{
    no warnings 'redefine';
    local *Time::HiRes::utime = sub {
        die "Time::HiRes::utime(): unimplemented in this platform\n";
    };

    lives_ok { set_mtime($file, 1_700_000_124.75) }
        'set_mtime survives an unimplemented Time::HiRes::utime';

    my @stat = stat($file);
    is($stat[9], 1_700_000_124,
        'the builtin fallback sets the mtime to whole seconds');
}

# Anything other than the unimplemented croak is a real failure and is not
# quietly retried and swallowed.
{
    no warnings 'redefine';
    local *Time::HiRes::utime = sub { die "utime failed: permission denied\n" };

    throws_ok { set_mtime($file, 1_700_000_124) } qr/permission denied/,
        'a real utime failure still propagates';
}

# Where Time::HiRes works, the helper keeps its sub-second precision.
SKIP: {
    skip 'sub-second mtimes are not available here', 1 if $^O eq 'MSWin32';

    set_mtime($file, 1_700_000_124.75);
    my @stat = Time::HiRes::stat($file);
    ok(abs($stat[9] - 1_700_000_124.75) < 0.01,
        'the normal path keeps sub-second precision');
}

done_testing();
