#!/usr/bin/env perl

# No script in the distribution may be started by anything but perl.
#
# This is not cosmetic.  perl hands a script whose #! line does not mention perl
# to the interpreter that line names (see perlrun).  With a server there - the
# launcher's shebang was "#!/usr/bin/env morbo" in 0.017.0 - morbo started the
# application as "perl script/database-bi daemon", perl passed it back to
# morbo, and every worker became another morbo: a process a second, each one
# exporting the whole of @INC as PERL5LIB until exec failed with "Argument list
# too long", with every generation keeping the listening socket.  The failure
# takes a minute to appear and then looks like a resource limit, so the shebangs
# are checked here instead.
#
# The scripts are every executable file in MANIFEST plus everything under
# script/ and bin/ - MANIFEST is what a distribution ships, so a script added
# without an entry is caught by t/manifest.t rather than silently skipped here.
# Nothing is executed; the files are read.
#
#   prove -l t/launcher.t

use strict;
use warnings;

use Test::Most;

my $launcher = 'script/database-bi';

# ---------------------------------------------------------------------------
# Every script starts with a perl shebang
# ---------------------------------------------------------------------------

sub _distribution_scripts {
	my @found;

	open my $mfh, '<', 'MANIFEST' or BAIL_OUT("cannot read MANIFEST: $!");
	while (my $line = <$mfh>) {
		chomp $line;
		next unless length $line;
		my ($file) = split /\s+/, $line;
		next unless defined($file) && -f $file;
		next unless $file =~ m{\A(?:script|bin)/} || -x $file;
		push @found, $file;
	}
	close $mfh;

	return sort @found;
}

my @scripts = _distribution_scripts();

ok(scalar(@scripts), 'the distribution has scripts to check')
	or BAIL_OUT('the MANIFEST scan found no scripts, so it is not testing anything');

ok(scalar(grep { $_ eq $launcher } @scripts), "$launcher is among them")
	or BAIL_OUT("$launcher is missing from the MANIFEST scan");

for my $script (@scripts) {
	open my $fh, '<', $script or BAIL_OUT("cannot read $script: $!");
	my $shebang = <$fh>;
	close $fh;

	like $shebang // '', qr{\A#![^\n]*\bperl\b},
		"$script is started by perl"
		or diag("a non-perl shebang hands the script to that interpreter, "
			. "which restarts it if it is a server");
}

# ---------------------------------------------------------------------------
# The launcher itself, with no arguments, is the reloading development server
# ---------------------------------------------------------------------------

ok(-f $launcher, "$launcher exists") or BAIL_OUT("no $launcher to check");

open my $fh, '<', $launcher or BAIL_OUT("cannot read $launcher: $!");
my $source = do { local $/; <$fh> };
close $fh;

# morbo runs the script as "perl <script> daemon", so a launcher that answered
# with the command list when it has no arguments would not start a server.
like $source // '', qr{Mojo::Server::Morbo},
	'the launcher starts the reloading server itself';
like $source // '', qr{Mojolicious::Commands->start_app},
	'and still hands a command word to the application';

done_testing();
