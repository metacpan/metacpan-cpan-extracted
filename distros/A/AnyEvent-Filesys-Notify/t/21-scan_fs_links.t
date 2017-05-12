use Test::More;
use Data::Dump qw(ddx);
use strict;
use warnings;
use lib 't/lib';

use TestSupport qw(create_test_files delete_test_files $dir);
use AnyEvent::Filesys::Notify;

# Tests for RT#72849

plan( skip_all => 'symlink not implemented on Win32' ) if $^O eq 'MSWin32';

# Setup for test by creating a broken symlink
create_test_files('original');
symlink File::Spec->catfile( $dir, 'original' ),
  File::Spec->catfile( $dir, 'link' )
  or die "Unable to create a link: $!";
delete_test_files('original');

# Scan it once, should be skipped on ext4
my $old_fs = AnyEvent::Filesys::Notify->_scan_fs($dir);
is( keys %$old_fs, 1, '_scan_fs: got links' ) or diag ddx $old_fs;

# Now see if we get warnings
my $new_fs           = AnyEvent::Filesys::Notify->_scan_fs($dir);
my @warnings_emitted = ();
my @events           = do {
    local $SIG{__WARN__} = sub {
        push @warnings_emitted, shift;
    };
    AnyEvent::Filesys::Notify->_diff_fs( $old_fs, $new_fs );
};
ok( !@warnings_emitted, '... without warnings' )
  or diag join "\n", @warnings_emitted;

done_testing();
