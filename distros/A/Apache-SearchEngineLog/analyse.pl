#!/usr/bin/perl -w
# analyse.pl
# part of Apache::SearchEngineLog

use strict;
use DBI;
use Getopt::Long;

my $host = 'localhost';
my $db = '';
my $user = (defined $ENV{'USER'} ? $ENV{'USER'} : '');
my $passwd = '';
my $output = '';
my $type = 'mysql';
my $list = 0;
my $vhost = '';
my $sort = 'uri';

Getopt::Long::config ('pass_through');
my $result = GetOptions
(
	'host|h=s'	=>	\$host,
	'db|d=s'	=>	\$db,
	'user|u=s'	=>	\$user,
	'password|p=s'	=>	\$passwd,
	'output|o=s'	=>	\$output,
	'type|t=s'	=>	\$type,
	'list|l'	=>	\$list,
	'vhost|v=s'	=>	\$vhost,
	'sort|s=s'	=>	\$sort

);

if (!$db or !$user)
{
	die <<EOF;
Usage: $0 --db=<database> [options]

	-d <name>	--db		Name of the database to use (required!)
	-t <type>	--type		Type of the DB (default: mysql)
	-h <host>	--host		Host to connect to (default: localhost)
	-u <user>	--user		User to log into the database
	-p <passwd>	--password	Password to log into the database

	-l		--list		Print list of all vhosts and exit
	-v <vhosts>	--vhost		Commaseperated list of vhosts
	-s <uri|term>	--sort		Sort by either uri or searchterm
	-o <file>	--output	File to write output to

EOF
}

my $DBH = DBI->connect ("DBI:$type:database=$db;host=$host", $user, $passwd) or die DBI->errstr ();

print_list ($DBH) if $list; #and exit..

if ($output)
{
	open (OUT, "> $output") or die $!;
}
else
{
	*OUT = *STDOUT;
}

my $primsth;
my $secsth;
if (lc ($sort) eq 'uri')
{
	$primsth = $DBH->prepare ("SELECT uri, count(*) AS cnt FROM hits WHERE vhost = ? GROUP BY uri ORDER BY cnt DESC");
	$secsth  = $DBH->prepare ("SELECT term, count(*) AS cnt FROM hits WHERE vhost = ? AND uri = ? GROUP BY term ORDER BY cnt DESC");
}
elsif (lc ($sort) eq 'term')
{
	$primsth = $DBH->prepare ("SELECT term, count(*) AS cnt FROM hits WHERE vhost = ? GROUP BY term ORDER BY cnt DESC");
	$secsth = $DBH->prepare ("SELECT uri, count(*) AS cnt FROM hits WHERE vhost = ? AND term = ? GROUP BY uri ORDER BY cnt DESC");
}

$vhost ||= get_list ($DBH);

foreach my $virtual (split (m#,\s*#, $vhost))
{
	print OUT '#' x 75 . "\n";
	print OUT "# Statistic for $virtual" . ' ' x (58 - length ($virtual)) . "#\n";
	print OUT '#' x 75 . "\n\n";

	$primsth->execute ($virtual) or die $primsth->errstr ();

	while (my ($thing, $count) = $primsth->fetchrow_array ())
	{
		print OUT '=' x 75 . "\n";
		print OUT "  $thing  ($count)\n";
		print OUT '-' x 75 . "\n";

		$secsth->execute ($thing, $virtual) or die $secsth->errstr ();

		while (my ($thing, $count) = $secsth->fetchrow_array ())
		{
			my $pad = ' ' x (55 - length ($thing));
			print  OUT "  $thing$pad  ";
			printf OUT ("%5u\n", $count);
		}

		print OUT "\n";

		$secsth->finish ();
	}

	print OUT "\n";

	$primsth->finish ();
}

$DBH->disconnect ();

if ($output)
{
	close OUT;
}

exit (0);



sub print_list
{
	my $DBH = shift;

	my $sth = $DBH->prepare ("SELECT vhost FROM hits GROUP BY vhost ORDER BY vhost ASC");
	$sth->execute ();

	print "List of known vhosts:\n";

	while (my ($vhost) = $sth->fetchrow_array ())
	{
		print "  $vhost\n";
	}

	print "\n";

	$sth->finish ();
	$DBH->disconnect ();

	exit (0);
}

sub get_list
{
	my $DBH = shift;

	my $sth = $DBH->prepare ("SELECT vhost FROM hits GROUP BY vhost ORDER BY vhost ASC");
	$sth->execute ();

	my @vhosts;

	while (my ($vhost) = $sth->fetchrow_array ())
	{
		push (@vhosts, $vhost);
	}

	$sth->finish ();

	return join (',', @vhosts);
}
