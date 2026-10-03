package FakeMDB;

# Test helper: installs stand-in mdb-tables, mdb-export and mdb-count
# scripts in a temporary directory, so that the exporter can be tested
# without mdbtools or a real Access database.
#
# The "database" is a text file listing one table name per line; the
# fake mdb-tables prints it back.  A first line of "FAIL" makes
# mdb-tables fail.  mdb-export's behaviour depends on the table name:
#   Broken   - exits 1 with "corrupt table" on stderr
#   Killed   - kills itself with SIGTERM (Unix only: Windows has no signals)
#   Unicode  - UTF-8 text that cp1252 can represent ("Cafe" with e-acute, Euro)
#   Japanese - UTF-8 text that cp1252 cannot represent
#   Latin1   - bytes that are not valid UTF-8
#   Truncated - output that stops in the middle of a UTF-8 character
#   Slow     - writes part of the table, then waits 30 seconds (for
#              interrupting an export half-way)
#   anything else - a two-line CSV naming the table

use strict;
use warnings;
use autodie qw(:all);

use File::Spec;
use File::Temp qw(tempdir);

use Exporter qw(import);
our @EXPORT_OK = qw(install_fake_mdbtools make_database fake_path);

# PATH as it was before any test changed it.  Tests set PATH to stand-in
# directories; appending the *current* PATH would carry an earlier directory
# (with all three programs) along, so a program meant to be missing would
# still be found.
my $ORIGINAL_PATH = $ENV{PATH} // '';

# fake_path(@programs): a whole PATH value for tests.  On Unix, only the
# stand-in directory, so real mdbtools cannot interfere.  On Windows the
# original PATH is kept after it: with PATH replaced entirely, Windows
# could not start any process at all (not even perl.exe).
sub fake_path {
	my $dir = install_fake_mdbtools(@_);
	return $dir unless $^O eq 'MSWin32';
	require Config;
	return join($Config::Config{path_sep}, $dir, $ORIGINAL_PATH);
}

# Windows: the stand-ins are Perl scripts with a .cmd file beside each,
# so that File::Which finds them (through PATHEXT).  But IPC::Run3 starts
# programs with CreateProcess, which can only run real executables, not
# .cmd files; and going through cmd.exe instead would let it interpret
# "&", "|" and "%" in table names.  So, on Windows only, run3 is wrapped:
# a call to a stand-in "X.cmd" becomes "perl X.pl ..." - still a direct
# list-form call, with no shell.  Real mdbtools on Windows are .exe files
# and are not affected.  Both IPC::Run3's run3 and the copy the Exporter
# imported are wrapped, whichever was loaded first.
_redirect_stand_ins() if $^O eq 'MSWin32';

sub _redirect_stand_ins {
	require IPC::Run3;
	my %wrapped;
	my $wrap = sub {
		my $name = shift;
		no strict 'refs';
		my $original = defined(&{$name}) ? \&{$name} : return;
		return if $wrapped{$original};
		my $wrapper = sub {
			my ($cmd, @rest) = @_;
			if(ref($cmd) eq 'ARRAY' && $cmd->[0] =~ /\A(.+)\.cmd\z/i && -f "$1.pl") {
				$cmd = [$^X, "$1.pl", @{$cmd}[1 .. $#{$cmd}]];
			}
			return $original->($cmd, @rest);
		};
		$wrapped{$wrapper} = 1;
		no warnings 'redefine';
		*{$name} = $wrapper;
		return;
	};
	$wrap->('IPC::Run3::run3');
	$wrap->('App::Access2CSV::Exporter::run3');
	return;
}

# Shared prologue of every fake program.  It parses the command line the
# way the real mdbtools (glib's option parser) does: options are
# recognised anywhere, not only before the file name, until a "--" ends
# them.  An unknown option is an error, as in mdbtools.  If
# FAKE_MDB_ARGV_LOG is set, each program appends its argv there, one
# argument per line, followed by an empty line.
my $PROLOGUE = <<'PERL';
my %known = map { $_ => 1 } @KNOWN;
my (@positional, %options, $ended);
if(my $log = $ENV{FAKE_MDB_ARGV_LOG}) {
	open my $lfh, '>>', $log or die "$log: $!";
	print {$lfh} map({ "$_\n" } $0 =~ m{([^/]+)\z}, @ARGV), "\n";
	close $lfh;
}
foreach my $arg (@ARGV) {
	if(!$ended && $arg eq '--') { $ended = 1; next }
	if(!$ended && $arg =~ /\A-./) {
		if(!$known{$arg}) { print STDERR "option parsing failed: Unknown option $arg\n"; exit 1 }
		$options{$arg} = 1;
		next;
	}
	push @positional, $arg;
}
PERL

# Program bodies; each is run by the perl that runs the tests
my %SCRIPTS = (
	'mdb-tables' => [['-1'], <<'PERL'],
my ($db) = @positional;
open my $fh, '<:raw', $db or do { print STDERR "cannot open $db\n"; exit 1 };
my @lines = <$fh>;
if(@lines && $lines[0] =~ /^FAIL/) { print STDERR "not an Access database\n"; exit 2 }
binmode STDOUT;
print @lines;
PERL
	'mdb-export' => [[], <<'PERL'],
my ($db, $table) = @positional;
binmode STDOUT;
if($table eq 'Broken') { print STDERR "corrupt table\n"; exit 1 }
if($table eq 'Killed') { kill 'TERM', $$; sleep 5; exit 0 }
if($table eq 'Truncated') { print "\"id\"\n\"Caf\xC3"; exit 0 }
if($table eq 'Slow') { $| = 1; print "\"id\"\n1\n"; sleep 30; exit 0 }
my %body = (
	Unicode  => "Caf\xC3\xA9 \xE2\x82\xAC",
	Japanese => "\xE6\x97\xA5\xE6\x9C\xAC",
	Latin1   => "Caf\xE9",
);
my $value = exists $body{$table} ? $body{$table} : $table;
print "\"id\",\"name\"\n1,\"$value\"\n";
PERL
	'mdb-count' => [[], <<'PERL'],
print "1\n";
PERL
);

# install_fake_mdbtools(@programs)
# Writes the named fake programs (default: all three) to a new temporary
# directory and returns that directory, for prepending to $ENV{PATH}.
sub install_fake_mdbtools {
	my @programs = @_ ? @_ : sort keys %SCRIPTS;

	my $dir = tempdir(CLEANUP => 1);
	foreach my $program (@programs) {
		# On Windows the script is a .pl file, started by a .cmd shim of the
		# same name (found through PATHEXT), because Windows ignores "#!"
		my $path = File::Spec->catfile($dir, $^O eq 'MSWin32' ? "$program.pl" : $program);
		open my $fh, '>', $path;
		my ($known, $body) = @{ $SCRIPTS{$program} };
		print {$fh} "#!$^X\nuse strict;\nuse warnings;\nmy \@KNOWN = qw(@{$known});\n$PROLOGUE$body";
		close $fh;
		chmod 0755, $path;

		if($^O eq 'MSWin32') {
			open my $shim, '>', File::Spec->catfile($dir, "$program.cmd");
			print {$shim} qq{\@"$^X" "%~dp0$program.pl" %*\r\n};
			close $shim;
		}
	}
	return $dir;
}

# make_database($dir, @tables)
# Creates a fake database listing @tables and returns its path.
sub make_database {
	my ($dir, @tables) = @_;

	my $path = File::Spec->catfile($dir, 'test.accdb');
	open my $fh, '>:raw', $path;
	print {$fh} map { "$_\n" } @tables;
	close $fh;
	return $path;
}

1;
