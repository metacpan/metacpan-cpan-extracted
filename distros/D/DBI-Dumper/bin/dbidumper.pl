#!/usr/bin/perl
#
=pod

=head1 NAME

dbidumper - dump database to delimited file

=head1 SYNOPSIS

	dbidumper [OPTION]...

	<< meanwhile in your control file >>
	OPTIONS (export=100,rows=100)
	EXPORT DATA REPLACE INTO FILE 'test.dat'
	FIELDS TERMINATED BY TAB ENCLOSED BY '"' AND '"'
	WITH HEADER FROM
	SELECT * FROM MY_TABLE

=head1 DESCRIPTION

Dumps data from a select statement into an output file. dbidumper tries to
mirror the functionality and behavior of sql*loader. The control file syntax is
similar, and dbidumper utilizes a subset of the sql*loader options. Options can
also be specified in the control file. The command line versions take
precedence.

=over

=item userid=username/password@sid

Login information for database connection.

B<Note:> For security reasons, it is customary to place this option inside the
control file.

If the sid includes a colon, the full string will be used as the DBI dsn. For example:

	userid=username/password@mysql:database

Will connect to mysql's 'database' database as username.

If the environment variable ORACLE_SID is available, it will be used if not
specified here.

=item control=filename

Input control filename. Defaults to standard input. See L<CONTROL FILE> for
layout and description.

=item output=filename

Output filename for data. Defaults to standard output. If rows is given, can
contain template consisting of three or more Xs. The Xs will be replaced with
the file sequence number. If the template does not contain three or more Xs,
the sequence number will be appended to the filename with a dot. Examples:

=over

=item rows=1000 output=outputXXXXX.dat

Data will be written to output00001.dat, output00002.dat, etc.

=item rows=1000 output=output.dat

Data will be written to output.dat.0001, output.dat.0002, etc.

=item output=outputXXXXX.dat

Data will be written to outputXXXXX.dat

=back

=item rows=n

Number of rows per output file. Defaults to all rows in one output file.

=item export=n

Total number of rows to export. Use to limit output or restart dump.

=item skip=n

Number of rows to skip from beginning. File sequence number will be preserved,
so if rows=n is set, this can be used to restart a job.

=item writesize=n

Block size to write file. Defaults to write each record as returned from
database. If set, dbidumper will collect rows into a buffer at most n bytes large
before writing to file.

=item silent=true

Suppress normal logging information. dbidumper will only report errors.

=back

=head1 DEPENDENCIES

This program depends on the following perl modules, available from a CPAN
mirror near you:

=over

=item Parse::RecDescent - Recursive parser

=item DBI - Standard database interface

=back

=head1 CONTROL FILE

The control file used for dbidumper is very similar to sql*loader's. The full
specification is:

	[ OPTIONS ([option], ...) ]
	EXPORT DATA [ REPLACE | APPEND ] [ INTO FILE 'filename' ]
	[ FIELDS
		[ TERMINATED [BY] {TAB | 'string' | X'hexstring'} ] |
		[ ENCLOSED [BY] {'string' | X'hexstring'} 
			[AND] ['string' | X'hexstring'] ]
	]
	[ WITH HEADER ]
	FROM
	select_statement

=head1 AUTHOR

Written by Warren Smith (warren.smith@acxiom.com)

=head1 BUGS

None yet.

=cut

use strict;
use warnings;

use DBI;
use DBI::Dumper;
use Time::HiRes qw(time);
sub debug($);

my $start_time = time;

# preparse command line to get control parameter
my $control_fn = '';
for my $option (@ARGV) {
	next unless $option =~ /^control=(.*)/i;
	$control_fn = $1;
}

my $dumper = DBI::Dumper->new;

# slurp in the control file (stdin if not specified)
my $control_fh;
if($control_fn) {
	open $control_fh, "<", $control_fn
		or die "Could not open control file $control_fn: $!";
}
else {
	open $control_fh, "<&STDIN";
}
my $control_text = join("\n", <$control_fh>);
close $control_fh;

$dumper->control_text($control_text);
$dumper->prepare();

# parse command line arguments
#  these are done after the control file is read because they have precedence
for my $option (@ARGV) {
	if($option =~ /(\w*?)=(.*)/) {
		my ($key, $val) = ($1, $2);
		if($key =~ /^(userid|control|rows|export|skip|bindsize|silent|output)$/i) {
			$dumper->{lc $key} = $val;
		}
		else {
			die "Unrecognized option: $option";
		}
	}
	else {
		die "Invalid option: $option";
	}
}

my $connect_time = time;
# execute query
debug "Connecting to database...";
my $dbh = login();
debug "done.\n";

debug "Executing query...";
my $sth = $dbh->prepare($dumper->query);
$sth->execute;
debug "done.\n";

my $line_count = $dumper->execute($sth);

my $end_time = time;
my $dump_duration = $end_time - $start_time;
my $prepare_duration = $start_time - $connect_time;
my $rows_per_second = $line_count / $dump_duration;

debug sprintf "Total preparation time: %.2f seconds.\n", $prepare_duration;

debug sprintf "%d row(s) dumped in %.2f seconds. %.3f rows per second.\n",
	$line_count, $dump_duration, $rows_per_second;
exit 0;

sub login {
	my $userid = $dumper->{userid} || $ENV{ORACLE_USERID} || $ENV{DBI_USERID};

	my($user, $pass, $sid);
	# userid is in oracle's form username[/password][@sid]
	# try os based authentication
	if($userid && $userid =~ m{^ / (?:@(.*))? $}x) {
		$user = "/";
		$pass = undef;
		$sid = $3;
	}
	elsif($userid && $userid =~ m{^ (.*?) (?:/(.*?))? (?:@(.*))? $}x) {
		$user = $1;
		$pass = $2;
		$sid = $3;
	}

	# check to see if Term::ReadKey is available
	if(! (defined $user && defined $pass)) {
		eval { use Term::ReadKey };
		if($@) {
			die("Please set ORACLE_USERID, pass option userid=, or install Term::ReadKey");
		}
	}

	if(! defined $user) {
		local $| = 1;
		print "Username: ";
		$user = <STDIN>;
		chomp $user;
	}
	if($user ne '/' && ! defined $pass) {
		local $| = 1;
		print "Password: ";
		ReadMode 'noecho';
		$pass = ReadLine;
		chomp $pass;
		ReadMode 'normal';
	}

	# if the sid has a colon, do not prepend Oracle:
	#  this way we can do other db's as well
	#  i.e. mysql:database
	$sid ||= '';
	$sid = 'Oracle:' . $sid unless $sid =~ /:/;

	# try to login 
	return DBI->connect("dbi:$sid", $user, $pass, { AutoCommit => 1, RaiseError => 1 });
}

sub debug($) {
	my ($msg) = @_;
	print STDERR $msg if $ENV{DEBUG};
}
