#!/usr/bin/perl -w
use strict;
use DBI;
use Carp;
use vars qw(%opts %conf);
use Getopt::Std;
use Data::Dumper;
use Date::Format;
use Net::SMTP;

getopts("dtc:MTh", \%opts);
&usage if ($opts{h}); 
&readconfigfile;

my $dbh	= DBI->connect("DBI:$WebStat::Config::database{driver}:$WebStat::Config::database{database}:$WebStat::Config::database{host}", "$WebStat::Config::database{user}", "$WebStat::Config::database{password}" );

die "Cannot connect to database: $DBI::errstr ($!)" unless $dbh;

$dbh->do("set SQL_BIG_TABLES=1");

# for each server: do something..
while( my ($server, $serverconfig) = each %WebStat::Config::server) {
	next if ($server eq "default");
	print "$server\n" if $opts{d};
	#print Data::Dumper->Dump([\$serverconfig], [qw($serverconfig)]) if $opts{d};

	# setup a few useful dates
	my %dates = (
				 today     => time2str("%Y-%m-%d", time), 
				 yesterday => time2str("%Y-%m-%d", time-(60*60*24)),
				 weekago   => time2str("%Y-%m-%d", time-(60*60*24*7)),
				 monthago  => time2str("%Y-%m-%d", time-(60*60*24*30))
				 );

	my %stats;

	my $serverquery;
	unless ($serverconfig->{alias}) {
	  $serverquery=qq[server="$server"];
	} else {
	 # $serverquery=qq[(server="]. join ('" or server="', $server,@{$serverconfig->{alias}}) .qq[")];
	  $serverquery= qq[server in ("]. join ('","', $server,@{$serverconfig->{alias}}) . qq[")]; 
	}

	if ($serverconfig->{urlpath}) {
	  $serverquery .= qq[ and urlpath regexp "$serverconfig->{urlpath}"];
	}

  # check things

	if ($opts{t}) {
	  $stats{today}   = CountThings($dates{today}, $serverquery);
	} else {
	  $stats{daily}   = CountThings($dates{yesterday}, $serverquery);
	  $stats{weekly}  = CountThings($dates{weekago}, $serverquery);
	  $stats{monthly} = CountThings($dates{monthago}, $serverquery);
	}


  # print or mail it ...
	my $data;
	$data .= "Statistics for $server";
    $data .= " [$serverconfig->{urlpath}]" if $serverconfig->{urlpath};
    $data .= " ($serverconfig->{description})" if $serverconfig->{description};
	$data .= "\n";

	# for the output below..
	$dates{daily} = $dates{yesterday};
	$dates{weekly} = $dates{weekago};
	$dates{monthly} = $dates{monthago};

	for my $time ($opts{t} ? "today" : qw(daily weekly monthly)) { 
	  $data .= "\n$time (from $dates{$time})\n";
	  $data .= sprintf("   % 3u users, % 5u hits % 8.0fKB\n", 
					   $stats{$time}{usercount}, $stats{$time}{hits}, $stats{$time}{traffic});
	  #$data .= "     $stats{$time}{pagehits} pageviews ($stats{$time}{pagetraffic}KB)\n";
	}

    $data .= "\n";
	
	my $timequery;
	unless ($opts{t}) {
	  $timequery = qq[(timeserved >= "$dates{yesterday}" and timeserved < "$dates{today}")];
	} else {
	  $timequery = qq[(timeserved >= "$dates{today}")];
	}

	
	$data .= "\nTop 20 domains visiting the site:\n";
	$data .= "   Hits  Domain\n";
	my $sqlcommand = qq[select substring(remotehost,locate(".",remotehost)+1,100) as subdims,\
						remoteip,count(remotehost) as c from $WebStat::Config::database{"table"} \
						where $serverquery and $timequery group by subdims order by c DESC LIMIT 20];
	print "sqlcommand: $sqlcommand\n" if $opts{d};
	my $sth = DoSql($sqlcommand);
	while (my ($subhost, $remoteip, $count) = $sth->fetchrow) {
	  $subhost = "unresolved" unless ($subhost);
	  $data .= sprintf("  % 5u: %s\n", $count, $subhost);
	}

	print "$data" unless ($opts{M});  

	if ($opts{M}) {
	  my $smtp = Net::SMTP->new('smtp');
	  die "Could not connect to smtp server" unless ($smtp);	  
	  my $mailfrom = $serverconfig->{mail}->{from} ? $serverconfig->{mail}->{from} : 
		$WebStat::Config::server{"default"}->{mail}->{from};
	  $smtp->mail($mailfrom);
	  my @mailto = $opts{T} ? @{$WebStat::Config::server{"default"}->{mail}->{rcpt}}
				: @{$serverconfig->{mail}->{rcpt}}; 
	  $smtp->to(@mailto); 
	  $smtp->data();
	  $smtp->datasend("From: $mailfrom\n");
	  $smtp->datasend("To: ". join (", ", @mailto)."\n" );
	  $smtp->datasend("Subject: Webstats for $server (". time2str("%Y-%m-%e", time) .")\n\n");
	  $smtp->datasend("$data\n");
	  $smtp->dataend();
	  $smtp->quit;
	}
}

#  
# Count users, hits and more for from the given period ..
#    args: $fromtime, $serverquery
#    returns: a hash with "the stats" (read the source :) )
sub CountThings {
  my ($fromtime, $serverquery) = @_;

  my ($sth, $timequery);

  my $table = $WebStat::Config::database{"table"};
  my $today = time2str("%Y-%m-%e", time);

  unless ("$fromtime" eq "$today") {
	$timequery = qq[(timeserved >= "$fromtime" and timeserved < "$today")];
  } else {
	$timequery = qq[(timeserved >= "$fromtime")];
  }

  my %stat;
  # hits
  $sth = DoSql(qq[select count(server),sum(bytes)/1024 from $table where $serverquery 
				  and $timequery]);
  ($stat{hits}, $stat{traffic}) = $sth->fetchrow;
  
 ## pageviews
 # $sth = DoSql(qq[select count(server),sum(bytes)/1024 from $table where $serverquery 
 #				  and $timequery
 #				  and (contenttype = 'text/plain' or contenttype = 'text/html')]);
 #($stat{pagehits}, $stat{pagetraffic}) = $sth->fetchrow;

  # users
  # use something like this to look at the "users" .
  # select server,urlpath,usertrack,remoteip,left(useragent,30),timeserved,
  # count(server) as c from  requests where server="www.monsted.com" and timeserved
  # >= "1998-06-20"  group by usertrack,remoteip order by remoteip;
  $sth = DoSql(qq[select count(server),remoteip from $table where $serverquery
				  and $timequery
				  group by usertrack]);

  $stat{usercount} = 0;
  my %visitors = ();
  while (my ($counts, $remoteip) = $sth->fetchrow) {
	# only count those who've looked at more than one page
	# (throw away spiders (and other who doesn't support cookies))
	if ($counts > 1) { 
	  # count it, he support cookies
	  $stat{usercount}++;
	} else { 
	  # remember the looser by hand
	  $visitors{$remoteip}++;
	}
  }
  # add the noncookies if they hit more than one page (maybe we just should add them?)
  for my $count (values %visitors) {
	$stat{usercount}++ if ($count > 1);
  }
  
  return \%stat;

}

sub DoSql {
	my $sqlcommand = shift;
	print "sqlcommand: $sqlcommand\n" if $opts{d};
	my $sth = $dbh->prepare($sqlcommand) 
	  or die "Could not prepare [$DBI::errstr] ($sqlcommand)";
	$sth->execute 
	  or die "Could not execute [$DBI::errstr] ($sqlcommand)";
	
    return $sth;
}

sub readconfigfile {
	my $conffile = $opts{c} || "./webstat.conf";	
	require $conffile;
 	if ($opts{d}) {
	 	#print Data::Dumper->Dump([\%WebStat::Config::server], [qw(server)]);
	 	#print Data::Dumper->Dump([\%WebStat::Config::database], [qw(database)]);
 	}
}


# count hits and traffic
#	 select count(bytes) as hits,sum(bytes) as trafik,server from requests group by server order by hits limit 20 ;


$dbh->disconnect;

undef %WebStat::Config::server;

exit;


sub usage {
    print STDERR <<EOT;
Usage: $0 [options]

Options:
    -d               Debug: print debug information.
	-c /config/file  Select configurationfile
	-t               Show hits for today (only)
	-M               Mail reports (default: print to stdout)
	-T               Test mode, only send mails to the default mail rcpt
    -h               This help
EOT
    exit(1);
}


__END__

# tests with referer stuff
#if ($conf{referer}) {
#	my $host = $conf{host} ? "and host=".$dbh->quote($conf{host}) : "";
#	my $sth = $dbh->prepare("select count(server),urlpath,referer from requests where referer not like ")

 # select count(server) as hits ,urlpath,referer from requests where referer not like CONCAT('http://', server, '%')  order by hits desc limit 10 ;

# THIS worked, I guess...
#my $sqlcommand = qq[select count(server) as hits ,urlpath,referer,server from requests where \
#                  (referer like 'http://%' or referer = '') and not (referer like CONCAT('http://', server, '%') \

# or referer like CONCAT('http://www.hip.dk/%') or referer like CONCAT('http://www.hilleroed-posten.dk/%') ) \
# and server='www.hillerod-posten.dk' group by referer,server order by hits desc limit 10];

while (my $r = $sth->fetchrow_hashref) {
	print qq($r->{hits}, $r->{urlpath}, $r->{referer}\n);		
}







