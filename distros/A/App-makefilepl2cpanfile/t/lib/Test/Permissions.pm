package Test::Permissions;

# Tells a test whether chmod can really take access away on this system.
#
# It cannot for root, and it cannot on Windows, where chmod only sets the
# read-only attribute.  Rather than guessing from $> or $^O, each function
# tries the operation on a scratch file and reports what actually happened.

use strict;
use warnings;

use Exporter qw(import);
use File::Temp qw(tempdir);

our @EXPORT_OK = qw(can_revoke_read can_revoke_search can_revoke_write);

my %cache;

# True if a file with mode 0 cannot be opened for reading.
sub can_revoke_read {
	return $cache{read} //= do {
		my $dir  = tempdir(CLEANUP => 1);
		my $file = "$dir/probe";
		open my $out, '>', $file or die "$file: $!";
		close $out;
		chmod 0, $file;
		my $blocked = !open(my $in, '<', $file);
		chmod 0600, $file;
		$blocked ? 1 : 0;
	};
}

# True if a file inside a mode-0 directory cannot be stat()ed.
sub can_revoke_search {
	return $cache{search} //= do {
		my $dir = tempdir(CLEANUP => 1);
		my $sub = "$dir/sub";
		mkdir $sub or die "$sub: $!";
		open my $out, '>', "$sub/probe" or die "$sub/probe: $!";
		close $out;
		chmod 0, $sub;
		my $blocked = !stat("$sub/probe");
		chmod 0700, $sub;
		$blocked ? 1 : 0;
	};
}

# True if no file can be created in a mode-0555 directory.
sub can_revoke_write {
	return $cache{write} //= do {
		my $dir = tempdir(CLEANUP => 1);
		chmod 0555, $dir;
		my $blocked = !open(my $out, '>', "$dir/probe");
		close $out if !$blocked;
		chmod 0700, $dir;
		$blocked ? 1 : 0;
	};
}

1;
