package Apache::DBILogger;

require 5.004;
use strict;
use Apache::Constants qw( :common );
use DBI;
use Date::Format;

$Apache::DBILogger::revision = sprintf("%d.%02d", q$Revision: 1.20 $ =~ /(\d+)\.(\d+)/o);
	$Apache::DBILogger::VERSION = "0.93";

sub reconnect($$) {
	my ($dbhref, $r) = @_;

	$$dbhref->disconnect;

	$r->log_error("Reconnecting to DBI server");

	$$dbhref = DBI->connect($r->dir_config("DBILogger_data_source"), $r->dir_config("DBILogger_username"), $r->dir_config("DBILogger_password"));
  
  	unless ($$dbhref) { 
  		$r->log_error("Apache::DBILogger could not connect to ".$r->dir_config("DBILogger_data_source")." - ".$DBI::errstr);
  		return DECLINED;
  	}
}

sub logger {
	my $r = shift->last;

	my $s = $r->server;
	my $c = $r->connection;

	my %data = (
		    'server'	=> $s->server_hostname,
		    'bytes'     => $r->bytes_sent,
		    'filename'	=> $r->filename || '',
		    'remotehost'=> $c->remote_host || '',
		    'remoteip'  => $c->remote_ip || '',
		    'status'    => $r->status || '',
		    'urlpath'	=> $r->uri || '',
		    'referer'	=> $r->header_in("Referer") || '',	
		    'useragent'	=> $r->header_in('User-Agent') || '',
		    'timeserved'=> time2str("%Y-%m-%d %X", time),
		    'contenttype' => $r->content_type || ''
	);

	if (my $user = $c->user) {
		$data{user} = $user;
	}

	$data{usertrack} = $r->notes('cookie') || '';

	my $dbh = DBI->connect($r->dir_config("DBILogger_data_source"), $r->dir_config("DBILogger_username"), $r->dir_config("DBILogger_password"));
  
  	unless ($dbh) { 
  		$r->log_error("Apache::DBILogger could not connect to ".$r->dir_config("DBILogger_data_source")." - ".$DBI::errstr);
  		return DECLINED;
  	}
  	
  	my @valueslist;
  	
  	foreach (keys %data) {
		$data{$_} = $dbh->quote($data{$_});
		push @valueslist, $data{$_};
	}

	my $table = $r->dir_config("DBILogger_table") || 'requests';

	my $statement = "insert into $table (". join(',', keys %data) .") VALUES (". join(',', @valueslist) .")";

	my $tries = 0;
	
  	TRYAGAIN: my $sth = $dbh->prepare($statement);
  	
  	unless ($sth) {
  		$r->log_error("Apache::DBILogger could not prepare sql query ($statement): $DBI::errstr");	
  		return DECLINED;
  	}

	my $rv = $sth->execute;

	unless ($rv) {
		$r->log_error("Apache::DBILogger had problems executing query ($statement): $DBI::errstr");
	#	unless ($tries++ > 1) {
	#		&reconnect(\$dbh, $r);
	#		goto TRYAGAIN;
	#	}
	}
	
	$sth->finish;


	$dbh->disconnect;

	OK;
}

# #perl pun: <q[merlyn]> windows is for users who can't handle the power of the mac.

sub handler { 
	shift->post_connection(\&logger);
	return OK;
}

1;
__END__

=head1 NAME

Apache::DBILogger - Tracks what's being transferred in a DBI database

=head1 SYNOPSIS

  # Place this in your Apache's httpd.conf file
  PerlLogHandler Apache::DBILogger

  PerlSetVar DBILogger_data_source    DBI:mysql:httpdlog
  PerlSetVar DBILogger_username       httpduser
  PerlSetVar DBILogger_password       secret
  PerlSetvar DBILogger_table          requests
  
Create a database with a table named B<requests> like this:

CREATE TABLE requests (
  server varchar(127) DEFAULT '' NOT NULL,
  bytes mediumint(9) DEFAULT '0' NOT NULL,
  user varchar(15) DEFAULT '' NOT NULL,
  filename varchar(200) DEFAULT '' NOT NULL,
  remotehost varchar(150) DEFAULT '' NOT NULL,
  remoteip varchar(15) DEFAULT '' NOT NULL,
  status smallint(6) DEFAULT '0' NOT NULL,
  timeserved datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  contenttype varchar(50) DEFAULT '' NOT NULL,
  urlpath varchar(200) DEFAULT '' NOT NULL,
  referer varchar(250) DEFAULT '' NOT NULL,
  useragent varchar(250) DEFAULT '' NOT NULL,
  usertrack varchar(100) DEFAULT '' NOT NULL,
  KEY server_idx (server),
  KEY timeserved_idx (timeserved)
);

Its recommended that you include

use Apache::DBI;
use DBI;
use Apache::DBILogger;

in your startup.pl script. Please read the Apache::DBI documentation for
further information.

=head1 DESCRIPTION

This module tracks what's being transfered by the Apache web server in a 
SQL database (everything with a DBI/DBD driver).  This allows to get 
statistics (of almost everything) without having to parse the log
files (like the Apache::Traffic module, just in a "real" database, and with
a lot more logged information).

Apache::DBILogger will track the cookie from 'mod_usertrack' if it's there.

After installation, follow the instructions in the synopsis and restart 
the server.
	
The statistics are then available in the database. See the section VIEWING
STATISTICS for more details.

=head1 PREREQUISITES

You need to have compiled mod_perl with the LogHandler hook in order
to use this module. Additionally, the following modules are required:

	o DBI
	o Date::Format

=head1 INSTALLATION

To install this module, move into the directory where this file is
located and type the following:

        perl Makefile.PL
        make
        make test
        make install

This will install the module into the Perl library directory. 

Once installed, you will need to modify your web server's configuration
file so it knows to use Apache::DBILogger during the logging phase.

=head1 VIEWING STATISTICS

Please see the bin/ directory in the distribution for a
statistics script.

Some funny examples on what you can do might include:

=over 4

=item hit count and total bytes transfered from the virtual server www.company.com

    select count(id),sum(bytes) from requests 
    where server="www.company.com"

=item hit count and total bytes from all servers, ordered by number of hits

    select server,count(id) as hits,sum(bytes) from requests
    group by server order by hits desc

=item count of hits from macintosh users

    select count(id) from requests where useragent like "%Mac%"

=item hits and total bytes in the last 30 days
    select count(id),sum(bytes) from requests where
    server="www.company.com" and TO_DAYS(NOW()) -
    TO_DAYS(timeserved) <= 30

This is pretty unoptimal.  It would be faster to calculate the dates
in perl and write them in the sql query using f.x. Date::Format.


=item hits and total bytes from www.company.com on mondays.

    select count(id),sum(bytes) from requests where
    server="www.company.com" and dayofweek(timeserved) = 2

=back

It's often pretty interesting to view the referer info too.

See your sql server documentation of more examples. I'm a happy mySQL
user, so I would continue on

http://www.tcx.se/Manual_chapter/manual_toc.html

=head1 LOCKING ISSUES

MySQL 'read locks' the table when you do a select. On a big table
(like a large httpdlog) this might take a while, where your httpds
can't insert new logentries, which will make them 'hang' until the
select is done.

One way to work around this is to create another table
(f.x. requests_insert) and get the httpd's to insert to this table.

Then run a script from crontab once in a while which does something
like this:

  LOCK TABLES requests WRITE, requests_insert WRITE
  insert into requests select * from requests_insert
  delete from requests_insert
  UNLOCK TABLES

You can use the moverows.pl script from the bin/ directory.

Please note that this won't work if you have any unique id field!
You'll get duplicates and your new rows won't be inserted, just
deleted. Be careful.

=head1 TRAPS

I've experienced problems with 'Packets too large' when using
Apache::DBI, mysql and DBD::mysql 2.00 (from the Msql-mysql 1.18x
packages).  The DBD::mysql module from Msql-mysql 1.19_17 seems to
work fine with Apache::DBI.

You might get problems with Apache 1.2.x. (Not supporting
post_connection?)

=head1 SUPPORT

This module is supported via the mod_perl mailinglist
(modperl@apache.org, subscribe by sending a mail to
modperl-request@apache.org).

I would like to know which databases this module have been tested on,
so please mail me if you try it.

The latest version can be found on your local CPAN mirror or at
C<ftp://ftp.netcetera.dk/pub/perl/>

=head1 AUTHOR

Copyright (C) 1998, Ask Bjoern Hansen <ask@netcetera.dk>. All rights
reserved. This module is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), mod_perl(3)


=cut
