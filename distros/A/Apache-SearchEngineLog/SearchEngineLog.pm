package Apache::SearchEngineLog;
# Logging of terms used in searchengines

require 5.005;
use strict;
use warnings;

use Apache;
use Apache::Log;
use DBI;

use vars qw#$SERVER $REGEXEN $DBH $STH $TIMEOUT $LASTPING#;

our $VERSION = '0.51';

# to have the test-script run ok
return 1 if $0 eq 'test.pl';

init ();

return 1;
#List of subroutines:
# check_alive_dbi
# check_regexen
# cleanup
# connect_dbi
# db_save
# handler
# init

sub check_alive_dbi
##########################################################################
# Checks wether DB connection is alive by pinging it periodically.       #
# Reconnects if neccessary.                                              #
#                                                                        #
# Arguments:                                                             #
#  0: Apache::Log object                                                 #
#                                                                        #
# Returns:                                                               #
#  0: true if (re)conntected; false if reconnect fails                   #
##########################################################################
{
	my $l = shift;

	my $time = time;

	if (($time - $TIMEOUT) < $LASTPING)
	{
		return 1;
	}

	$l->debug ('Apache::SearchEngineLog: Timeout reached, pinging');

	if ($DBH->ping ())
	{
		$LASTPING = $time;
		return 1;
	}

	$l->info ('Apache::SearchEngineLog: Connection to database died: Reconnecting');
	return connect_dbi ($l);
}

sub check_regexen
##########################################################################
# Uses regexen to check which rule applies to a given server (if any)    #
# and returns the parameter field which contains usefull information.    #
#                                                                        #
# Arguments:                                                             #
#  0: Name of server as string                                           #
#                                                                        #
# Returns:                                                               #
#  0: Name of parameter                                                  #
##########################################################################
{
	my $server = shift;
	my $retval = '';

	foreach my $re (keys %$REGEXEN)
	{
		if ($server =~ m#$re#)
		{
			$retval = $REGEXEN->{$re};
			last;
		}
	}

	return $retval;
}

sub cleanup
##########################################################################
# Checks wether DB connection is alive by pinging it periodically.       #
# Reconnects if neccessary.                                              #
#                                                                        #
# Arguments:                                                             #
#  None                                                                  #
#                                                                        #
# Returns:                                                               #
#  0: true                                                               #
##########################################################################
{
	$DBH->disconnect ();
	return 1;
}

sub connect_dbi
##########################################################################
# Connects to the database.                                              #
#                                                                        #
# Arguments:                                                             #
#  0: Apache::Log object                                                 #
#                                                                        #
# Returns:                                                               #
#  0: true if successfully connected, false otherwise                    #
##########################################################################
{
	my $l = shift;

	my $db_source = $ENV{'DBI_data_source'} or $l->error ("Apache::SearchEngineLog: DBI_data_source not defined");
	my $db_user   = $ENV{'DBI_username'} or $l->error ("Apache::SearchEngineLog: DBI_username not defined");
	my $db_passwd = $ENV{'DBI_password'} or $l->error ("Apache::SearchEngineLog: DBI_password not defined");
	my $db_table  =	(defined $ENV{'DBI_table'} ? $ENV{'DBI_table'} : 'hits');

	if ($DBH = DBI->connect ($db_source, $db_user, $db_passwd))
	{
		$l->info ("Apache::SearchEngineLog: Database connection established");
	}
	else
	{
		$l->error ('Apache::SearchEngineLog: Unable to connect: ' . DBI->errstr ());
		return 0;
	}

	if ($STH = $DBH->prepare ("INSERT INTO $db_table (date, domain, term, uri, vhost) VALUES (NOW(), ?, ?, ?, ?)"))
	{
		$LASTPING = time;
		return 1;
	}
	else
	{
		$l->error ('Apache::SearchEngineLog: ' . $DBH->errstr ());
		return 0;
	}
	
	return undef;
}

sub db_save
##########################################################################
# Saves the given arguments to the database.                             #
#                                                                        #
# Arguments:                                                             #
#  0: Name of the remote server                                          #
#  1: The URI requested                                                  #
#  2: Name of the virtual host                                           #
#  @: Terms used in the search engine                                    #
#                                                                        #
# Returns:                                                               #
#  0: true                                                               #
##########################################################################
{
	my $server = shift;
	my $uri = shift;
	my $hostname = shift;

	foreach my $term (@_)
	{
		if ($STH->execute ($server, $term, $uri, $hostname))
		{
			$LASTPING = time;
		}
		else
		{
			warn $STH->errstr ();
		}
	}

	return 1;
}

sub handler
##########################################################################
# The handler called by Apache. It analyses the request and the referer  #
# and eventually calls other subroutines to assist in this task. This    #
# is the heart of this program..                                         #
#                                                                        #
#                                                                        #
# Arguments:                                                             #
#  0: Apache::Request object                                             #
#                                                                        #
# Returns:                                                               #
#  0: true                                                               #
##########################################################################
{
	my $r = shift or return undef;
	my %h = $r->headers_in ();
	my $l = $r->log ();

	$l->debug ("Apache::SearchEngineLog: handling request..");

	# first step: check for a (valid and usfull) referer
	unless (defined $h{'Referer'})
	{
		$l->debug ("Apache::SearchEngineLog: no referer defined..");
		return 1;
	}

	my $referer = $h{'Referer'};

	my $status = $r->status ();
	if ($status >= 400)
	{
		$l->debug ("Apache::SearchEngineLog: Not handling status code #$status..");
		return 1;
	}

	my ($server, $params);
	# referers are always http.. prove me wrong if i should be..
	# https shouldn't work either I belive..
	if ($referer =~ m#^http://([^/]+)/[^\?]+\?(.+)$#)
	{
		$server = $1;
		$params = $2;
	}
	else
	{
		$l->debug ("Apache::SearchEngineLog: No parameters present..");
		return 1;
	}

	# referer looks fairly usefull.. let's check this..
	my %params; # i know some people don't like this.. I do ;)
	foreach (split (m#\&#, $params))
	{
		my ($key, $value) = split (m#=#, $_, 2);
		$value =~ y#+# #;
		$value =~ s#%([a-fA-F0-9]{2})#pack ("C", hex ($1))#eg;

		$params{$key} = $value;
	}

	my $field;
	if (!defined $SERVER->{$server})
	{
		$l->debug ("Apache::SearchEngineLog: Unknown server: $server! Checking..");

		# servers without an apropriate entry in $REGEXEN should
		# leave us here..
		$field = check_regexen ($server) or return 1;

		if (defined $params{$field})
		{
			$SERVER->{$server} = $field;

			check_alive_dbi ($l);

			my $sth = $DBH->prepare ("INSERT INTO config (domain, field) VALUES (?, ?)");
			$sth->execute ($server, $field);
			$sth->finish ();

			$l->info ("Apache::SearchEngineLog: Added new domain: $server");
		}
	}
	else
	{
		$l->debug ("Apache::SearchEngineLog: Known server: $server");
		$field = $SERVER->{$server};
	}

	unless (defined $params{$field})
	{
		$l->info ("Apache::SearchEngineLog: Known server missing field: $server");
		return 1;
	}

	# ignore goggle's cache-parameters and related option
	if ($params{$field} =~ m#^(?:cache|related):\S+\s#)
	{
		# $' == everything right of match, FYI
		$params{$field} = $';
	}

	my $uri = $r->uri ();
	my $s = $r->server ();
	my $virtual = $s->server_hostname ();

	if ($status == 301 or $status == 302 or $status == 303 or $status == 307)
	{
		my $location;
		$location = $r->header_out ('Location') or $location = '';
		
		if ($location =~ m#^http://([^/]+)(/[^\?]*)#)
		{
			my ($to_server, $to_uri) = ($1, $2);
			if ($to_server eq $virtual)
			{
				$l->info ("Apache::SearchEngineLog: $uri was redirected to $to_uri; logging the latter");
				$uri = $to_uri;
			}
		}
	}

	my @terms = ();
	foreach my $term (split (m#\s+#, $params{$field}))
	{
		$term =~ s#(^\W+)|(\W+$)##g;
		push (@terms, $term);
	}

	$l->debug ("Apache::SearchEngineLog: Saving to database");

	check_alive_dbi ($l) or return 1;
	db_save ($server, $uri, $virtual, @terms);

	return 1;
}

sub init
##########################################################################
# Initialises global variables, initiates the database connection, etc.. #
# Just what you'd expect an init routine to do.. ;)                      #
#                                                                        #
# Arguments:                                                             #
#  none                                                                  #
#                                                                        #
# Returns:                                                               #
#  0: true                                                               #
##########################################################################
{
	my $s = Apache->server ();
	my $l = $s->log ();

	$REGEXEN =
	{
		qr#yahoo\.#		=>	'p',
		qr#altavista\.#		=>	'q',
		qr#msn\.#		=>	'q',
		qr#voila\.#		=>	'kw',
		qr#lycos\.#		=>	'query',
		qr#search\.terra\.#	=>	'query',
		qr#google\.(?!yahoo)#	=>	'q',
		qr#alltheweb\.com#	=>	'q',
		qr#netscape\.#		=>	'search',
		qr#northernlight\.#	=>	'qr',
		qr#dmoz\.org#		=>	'search',
		qr#search\.aol\.com#	=>	'query',
		qr#www\.search\.com#	=>	'q',
		qr#askjeeves\.#		=>	'ask',
		qr#hotbot\.#		=>	'mt',
		qr#metacrawler\.#	=>	'general'
	};

	# ping database in this interval at the very most..
	$TIMEOUT = (defined $ENV{'DBI_timeout'} ? $ENV{'DBI_timeout'} : 120);
	connect_dbi ($l);

	Apache->server->register_cleanup (\&cleanup);

	$SERVER = {};

	# load known servers from database.. this is mostly to speed up
	# recognition later on..
	my $sth = $DBH->prepare ("SELECT domain, field FROM config");
	$sth->execute ();
	while (my ($d, $f) = $sth->fetchrow_array ())
	{
		$SERVER->{$d} = $f;
	}
	$sth->finish ();

	$l->debug ("Apache::SearchEngineLog: init done");

	return 1;
}

__END__

=head1 NAME

Apache::SearchEngineLog - Logging of terms used in search engines

=head1 SYNOPSIS

  #in httpd.conf

  PerlSetEnv DBI_data_source  dbi:driver:dsn
  PerlSetEnv DBI_username     username
  PerlSetEnv DBI_password     password
  PerlSetEnv DBI_table        db_table #optional, defaults to "hits"
  PerlSetEnv DBI_timeout      seconds  #optional, defaults to 120

  PerlModule Apache::SearchEngineLog

  <Location /test>
    PerlLogHandler Apache::SearchEngineLog
  </Location>

=head1 DESCRIPTION

Apache::SearchEngineLog logs the terms used at a search engine into a SQL
Database, making it easy to analyse it and in turn optimize your website.

=head1 TABLE LAYOUT

  The table "hits" should look somewhat like this:

  +--------+-------------+------+-----+---------------------+-------+
  | Field  | Type        | Null | Key | Default             | Extra |
  +--------+-------------+------+-----+---------------------+-------+
  | term   | varchar(50) |      |     |                     |       |
  | vhost  | varchar(20) |      | MUL |                     |       |
  | uri    | varchar(50) |      |     |                     |       |
  | domain | varchar(20) |      |     |                     |       |
  | date   | datetime    |      |     | 0000-00-00 00:00:00 |       |
  +--------+-------------+------+-----+---------------------+-------+

  This is the table "config":

  +--------+-------------+------+-----+---------+-------+
  | Field  | Type        | Null | Key | Default | Extra |
  +--------+-------------+------+-----+---------+-------+
  | domain | varchar(20) |      | PRI |         |       |
  | field  | varchar(10) |      |     |         |       |
  +--------+-------------+------+-----+---------+-------+

=head1 SEE ALSO

mod_perl(3), Apache(3)

=head1 AUTHOR

Florian Forster, octopus@verplant.org

=cut
