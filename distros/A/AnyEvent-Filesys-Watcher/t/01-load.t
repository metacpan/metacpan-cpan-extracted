use strict;
use warnings;

use Test::More;
use File::Find;

BEGIN {
	my $module;
	if ($^O eq 'linux') {
		$module = 'Linux/Inotify2.pm';
	} elsif ($^O eq 'darwin') {
		$module = 'Mac/FSEvents.pm';
	} elsif ('MSWin32' eq $^O || 'cygwin' eq $^O) {
		$module = 'Filesys/Notify/Win32/ReadDirectoryChanges.pm'
	} elsif ($^O =~ /bsd/i) {
		$module = 'IO/KQueue.pm';
	}

	if ($module) {
		eval { require $module };
		plan skip_all => 'no os-specific backend installed' if $@;
	}
}

BEGIN {
	find( {
			wanted => sub {
				return unless m{\.pm$};

				s{^lib/}{};
				s{.pm$}{};
				s{/}{::}g;

				return if m{Inotify2$} and $^O ne 'linux';
				return if m{FSEvents$} and $^O ne 'darwin';
				return if m{ReadDirectoryChanges$} and $^O ne 'MSWin32' && $^O ne 'cygwin';
				return if m{KQueue$} and $^O !~ /bsd/;

				Test::More::use_ok($_)
					or die "Couldn't use_ok $_";
			},
			no_chdir => 1,
		},
		'lib'
	);
	done_testing;
}
