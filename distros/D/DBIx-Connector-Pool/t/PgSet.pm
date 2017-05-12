package PgSet;
use strict;
use warnings;
use File::Temp 'tempdir';
use DBI;

our $binDir;
our $testdir;
our $version;
our $testdsn;
our $testuser;

sub initdb {
	chomp($binDir = `pg_config --bindir 2>&1`);
	die "no pg_config" if $binDir !~ /\/(\d+\.\d+)\//;
	$version = $1;
	$testdir = tempdir('dbdpgcae_testdatabase_XXXXXX', TMPDIR => 1, CLEANUP => 1) or die "no testdir";
	my $output = `$binDir/initdb --locale=C -E UTF8 -D $testdir/data 2>&1`;
	die "initdb failed: $output" if $?;
	1;
}

sub startdb {
	my $output = `netstat -na 2>&1`;
	die "netstat failed: $output" if $?;
	my %ports = map {$_ => undef} $output =~ /:(\d+)/gs;
	my $testport = 5449;
	++$testport while exists $ports{$testport};
	my $conf = "$testdir/data/postgresql.conf";
	open my $cfh, '>>', $conf or die "can't write to postgresql.conf";
	print $cfh "\n\n## DBD::PgCAE testing parameters\n";
	print $cfh "port=$testport\n";
	print $cfh "max_connections=5\n";
	print $cfh "log_statement = 'all'\n";
	print $cfh "log_line_prefix = '%m [%p] '\n";
	print $cfh "log_min_messages = 'DEBUG1'\n";
	print $cfh "log_filename = 'postgres%Y-%m-%d.log'\n";
	print $cfh "log_rotation_size = 0\n";
	print $cfh "listen_addresses='127.0.0.1'\n" if $^O =~ /Win32/;
	print $cfh "\n";
	close $cfh or die qq{Could not close "$conf": $!\n};
	my $option = '';

	if ($^O !~ /Win32/) {
		my $sockdir = "$testdir/data/socket";
		if (!-e $sockdir) {
			mkdir $sockdir;
		}
		$option = q{-o '-k socket'};
	}
	my $COM = qq{$binDir/pg_ctl $option -l $testdir/dbdpg_test.logfile -D $testdir/data start};
	$output = `$COM 2>&1`;
	die "pg_ctl failed: $output" if $?;
	sleep 2;
	$testdsn = "dbi:Pg:dbname=postgres;client_encoding=utf8;port=$testport";
	if ($^O =~ /Win32/) {
		$testdsn .= ';host=localhost';
	} else {
		$testdsn .= ";host=$testdir/data/socket";
	}
	$testuser = ((getpwuid $>)[0]);
	die "not connected $testdsn/$testuser: " . DBI::errstr()
		unless DBI->connect($testdsn, $testuser, '', {RaiseError => 0, PrintError => 0, AutoCommit => 1});
	1;
}

1;
