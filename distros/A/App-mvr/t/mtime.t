use strict;
use warnings;
# Requires root access, on a Linux system that can do tmpfs
use Test::Is qw/extended/;
use Test::More tests => 5;
use IPC::Run3;
use Capture::Tiny qw/capture/;
use Path::Tiny;
use App::mvr;


my $wd = path( 'corpus', path(__FILE__)->basename );
END { path($wd)->remove_tree }

path($wd)->remove_tree;
my $orig_file  = path($wd, 'one.txt');
$orig_file->touchpath;
my $orig_mtime = $orig_file->stat->mtime;

my ($dir) = path($wd, 'tmp')->mkpath;
my $cleanup = mount_tmpfs($dir);
END { $cleanup->() }
sleep 1;

my ($out, $err) = capture {
    local $App::mvr::VERBOSE = 2;
    mvr(source => $orig_file, dest => $dir);
};
is   $out => '';
like $err => qr/\QFile can't be renamed across filesystems; copying/, 'file was copied, not renamed';

my $new_file = path($wd, 'tmp', 'one.txt');
ok !$orig_file->exists, qq($orig_file doesn't exist);
ok $new_file->exists,   qq($new_file exists);

is $new_file->stat->mtime, $orig_mtime, 'mtime unchanged';

sub mount_tmpfs {
    my $dir = shift;

    # Creating a new filesystem to force the file to be copied, not renamed
    my $uid = $>;
    my $mount_cmd = ['sudo', 'mount',
        -t => 'tmpfs',
        # Size is a number of bytes, and gets rounded up to the nearest page
        # Our file is zero-size, so a single page is plenty.
        -o => "size=1,mode=0700,uid=${uid}",
        'tmpfs',
        $dir
    ];
    diag stringify_cmd($mount_cmd);
    run3 $mount_cmd, \*STDIN, \*STDERR, \*STDERR;

    return sub {
        my $umount_cmd = ['sudo', 'umount', $dir];
        diag stringify_cmd($umount_cmd);
        run3 $umount_cmd, \*STDIN, \*STDERR, \*STDERR;
    };
}

sub stringify_cmd {
    my $cmd = shift;
    return 'running ' . join ' ', map { "'$_'" } ref $cmd ? @$cmd : $cmd;
}
