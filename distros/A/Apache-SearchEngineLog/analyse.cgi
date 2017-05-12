#!/usr/bin/perl -w
# analyse.cgi
# part of Apache::SearchEngineLog

use strict;
use DBI;
use CGI qw#:cgi#;
use Apache;

use vars qw#$DB_DSN $DB_USER $DB_PASSWD $DB_TABLE $DBH $STHS#;

init () unless defined ($DBH);

my $vhost = param ('vhost');
$vhost = '' unless defined $vhost;

my $sort = param ('sort');
$sort = 'uri' unless defined $sort;

if ($sort =~ m#term#i)
{
	$sort = 'term';
}
else
{
	$sort = 'uri';
}

my $self = (defined $ENV{'SCRIPT_NAME'} ? $ENV{'SCRIPT_NAME'} : 'analyse.cgi');

print <<EOF;
Content-type: text/html

<html>
<head>
<title>Apache::SearchEngineLog - $self</title>
<style type="text/css">
<!--
th { color: black; background: gray; }
td { color: black; background: lightgray; }
//-->
</style>
</head>

<body>
EOF

if (!$vhost)
{
	print "<h1>List of virtual hosts</h1>\n\n<p>";

	my $first = 1;

	my $vhost = get_list ($DBH);
	foreach my $v (split (m#,\s*#, $vhost))
	{
		print "<br />\n" unless $first;
		$first = 0;

		print qq#<a href="$self?vhost=$v">$v</a>#;
	}

	print	"</p>\n\n";

	end_html ();

	exit (0);
}
else
{
	$vhost =~ s#[^a-zA-Z0-9\-\.]##g;

	$vhost || die;
}

foreach my $virtual (split (m#,\s*#, $vhost))
{
	my $primsth = $STHS->{$sort}{'prim'};
	my $secdsth  = $STHS->{$sort}{'secd'};

	print qq#<h1>Statistic for $virtual</h1>\n#;

	if ($sort eq 'uri')
	{
		print qq#<p>[ By uri | <a href="$self?vhost=$vhost&sort=term">By term</a> ] #;
	}
	else
	{
		print qq#<p>[ <a href="$self?vhost=$vhost&sort=uri">By uri</a> | By term ] #;
	}

	print qq#[ <a href="$self">Select a different virtual host</a> ]</p>\n#;

	print qq#<table>\n#;

	$primsth->execute ($virtual) or die $primsth->errstr ();

	while (my ($thing, $count) = $primsth->fetchrow_array ())
	{
		print	qq#  <tr>\n#
		.	qq#    <th colspan="2">$thing ($count)</th>\n#
		.	qq#  </tr>\n#;

		$secdsth->execute ($thing, $virtual) or die $secdsth->errstr ();

		while (my ($thing, $count) = $secdsth->fetchrow_array ())
		{
			print	qq#  <tr>\n#
			.	qq#    <td>$thing</td>\n#
			.	qq#    <td>$count</td>\n#
			.	qq#  </tr>\n#;
		}

		print "\n";

		$secdsth->finish ();
	}

	print	qq#</table>\n\n#;

	$primsth->finish ();
}

end_html ();

###############################

sub get_list
{
	my $sth = $STHS->{'vhosts'};
	$sth->execute ();

	my @vhosts;

	while (my ($vhost) = $sth->fetchrow_array ())
	{
		push (@vhosts, $vhost);
	}

	$sth->finish ();

	return join (',', @vhosts);
}

sub init
{
	die "Need to be run under mod_perl!" unless defined $ENV{'MOD_PERL'};

	my $s = Apache->server ();
	my $l = $s->log ();

	$DB_DSN    = $ENV{'DBI_data_source'} or $l->error ("Apache::SearchEngineLog: DBI_data_source not defined");
	$DB_USER   = $ENV{'DBI_username'} or $l->error ("Apache::SearchEngineLog: DBI_username not defined");
	$DB_PASSWD = $ENV{'DBI_password'} or $l->error ("Apache::SearchEngineLog: DBI_password not defined");
	$DB_TABLE  = (defined $ENV{'DBI_table'} ? $ENV{'DBI_table'} : 'hits');

	$DBH = DBI->connect ($DB_DSN, $DB_USER, $DB_PASSWD) or $l->error (DBI->errstr ());

	$STHS = {};

	$STHS->{'uri'}{'prim'} = $DBH->prepare ("SELECT uri, count(*) AS cnt FROM hits WHERE vhost = ? GROUP BY uri ORDER BY uri ASC");
	$STHS->{'uri'}{'secd'} = $DBH->prepare ("SELECT term, count(*) AS cnt FROM hits WHERE vhost = ? AND uri = ? GROUP BY term ORDER BY cnt DESC");

	$STHS->{'term'}{'prim'} = $DBH->prepare ("SELECT term, count(*) AS cnt FROM hits WHERE vhost = ? GROUP BY term ORDER BY cnt DESC");
	$STHS->{'term'}{'secd'} = $DBH->prepare ("SELECT uri, count(*) AS cnt FROM hits WHERE vhost = ? AND term = ? GROUP BY uri ORDER BY cnt DESC");

	$STHS->{'vhosts'} = $DBH->prepare ("SELECT vhost FROM hits GROUP BY vhost ORDER BY vhost ASC");

	return 1;
}

sub end_html
{
	print <<EOF;
<hr />
<p style="text-align: right;font-size: 8pt;">This script is part of
<a href="http://verplant.org/SearchEngineLog/">Apache::SearchEngineLog</a>,
written by Florian Forster &lt;octopus at verplant.org&gt;</p>

</body>
</html>
EOF

	return 1;
}
