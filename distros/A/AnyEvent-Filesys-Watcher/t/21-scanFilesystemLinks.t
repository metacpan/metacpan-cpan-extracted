use strict;
use warnings;

use Test::More;
use Data::Dump qw(ddx);

use AnyEvent::Filesys::Watcher;
use lib 't/lib';
use TestSupport qw(create_test_files delete_test_files);

# Tests for RT#72849

my $dir = $TestSupport::dir;

plan skip_all => 'symlink not implemented on Win32' if $^O eq 'MSWin32';

# Setup for test by creating a broken symlink
create_test_files 'original';

my $watcher = AnyEvent::Filesys::Watcher->new(
	directories => ["$dir/one"],
	callback => sub {},
);

symlink File::Spec->catfile($dir, 'original'),
  File::Spec->catfile($dir, 'link')
  or die "Unable to create symbolic link: $!";
delete_test_files('original');

# Scan it once, should be skipped.
my $old_fs = $watcher->_scanFilesystem($dir);
is keys %$old_fs, 1, '_scanFilesystem: got links' or diag ddx $old_fs;

# Now see if we get warnings
my $new_fs = $watcher->_scanFilesystem($dir);
my @warnings_emitted = ();
my @events = do {
	local $SIG{__WARN__} = sub {
		push @warnings_emitted, shift;
	};
	$watcher->_diffFilesystem($old_fs, $new_fs);
};
ok !@warnings_emitted, '... without warnings'
	or diag join "\n", @warnings_emitted;

done_testing;
