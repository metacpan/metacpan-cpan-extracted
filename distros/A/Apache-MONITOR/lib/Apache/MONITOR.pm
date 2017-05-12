package Apache::MONITOR;

require 5.005_62;
use strict;
use vars qw($VERSION @EXPORTER @ISA);
use warnings;
use String::CRC::Cksum qw(cksum);

use DB_File;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our @EXPORT = qw(SUBSCRIBE UNSUBSCRIBE NOTIFY SHOW);
our $VERSION = '0.02';

use URI::Escape;
use Apache::Constants qw(:common :http :response :methods);
use constant SUBSCRIBE_OK => 1;
use constant SUBSCRIBE_ALREADY => 2;
use constant SUBSCRIBE_ERROR => 3;

my $original_handler;

sub is_proxy_request
{
	my $r = shift;
	my $host = $r->header_in('Host');
	return 0 unless(  $host );
	return ($r->server->server_hostname ne $host);
}

sub handler {
        my $r = shift;
        $r->warn( "prr_handler 1");
	$r->warn( "------------------------------------------" );
        $r->warn( $r->the_request() );
        my $href = $r->headers_in();
        foreach (keys %$href)
        {
                $r->warn( "$_ -> $href->{$_}\n");
        }
        $r->warn( "------------------------------------------" );
        $r->warn( $r->server->server_hostname );
        $r->warn( $r->get_server_name );
	if( is_proxy_request($r) )
        {
		$r->warn( "IS PROXYREQ");
        }
        return DECLINED unless $r->method() eq 'MONITOR' ;
        $r->warn( "Filename " , $r->filename, "\n" );
        $r->warn( "Uri " , $r->uri, "\n" );
        $r->warn( "pathinfop " , $r->path_info, "\n" );
        $r->warn( "prr_handler 2");
 
        $r->method_number(M_GET);
 
        return OK;
}

sub hp_handler {
        my $r = shift;
	$r->warn( "hp handler 1");
	
	$r->set_handlers(PerlFixupHandler => undef);
        return DECLINED unless $r->method() eq 'MONITOR' ;
	$r->warn( "hp handler 2");

	$original_handler = $r->handler();
 
        $r->handler("perl-script");
        $r->set_handlers(PerlHandler => [ \&monitor_handler ] );
        $r->warn( "Filename " , $r->filename, "\n" );
        $r->warn( "Uri " , $r->uri, "\n" );
        $r->warn( "pathinfop " , $r->path_info, "\n" );
	$r->warn( "hp handler 3");

	if( $r->proxyreq() )
        {
		$r->warn( "IS PROXYREQ");
                $r->filename('');
        }

	$r->set_handlers(PerlAccessHandler => undef);
	$r->set_handlers(PerlAuthenHandler => undef);
	$r->set_handlers(PerlDispatchHandler => undef);
	$r->set_handlers(PerlTypeHandler => undef);
	$r->set_handlers(PerlFixupHandler => [ \&fixup ]);
 
        return OK;
}

sub fixup
{
	my $r = shift;
	$r->warn( "FIXUP1: handler is now " . $r->handler());

        $r->handler("perl-script");
        $r->set_handlers(PerlHandler => [ \&monitor_handler ] );
	$r->warn( "FIXUP2: handler is now " . $r->handler());

	$r->set_handlers(PerlFixupHandler => undef);

	return OK;
}

 
 
 
sub monitor_handler
{
        my $r = shift;

	my $state = 'NONE';

	my $host = $r->header_in( 'Host' );
        if( !defined $host || !$host)
        {
		#FIXME allow HTTP 1.0!
                return BAD_REQUEST;
        }

	my $monitored_uri = $r->uri;
	if($r->uri !~ /:\/\//)
	{
		$monitored_uri = "http://$host" . $r->uri;
	}
	$r->warn( "monitored URI:  $monitored_uri");

	my $mon_string = "";
	if( is_proxy_request($r) )
	{
		$mon_string = "proxy:" . $monitored_uri;
		my($cs,$rv,$msg) = poll_to_checksum($monitored_uri);
		$state = $cs;
		if($rv)
		{
			$r->warn( "error when polling remote resource: $msg");
		}
	}
	else
	{	
		my $monitor_code = get_monitor_code($r,$monitored_uri);
		$r->warn( "monitor_code: " . ( $monitor_code ? $monitor_code : "undef" ));

		if( (!$monitor_code) && (  ($r->filename =~ /cgi/) || (! -f $r->filename)) )
		{
			$r->warn( "monitor_handler HTTP_METHOD_NOT_ALLOWED");
			return HTTP_METHOD_NOT_ALLOWED;
		}
		if( $monitor_code )
		{
			$mon_string = "apply:" . $monitor_code;
		}
		else
		{
			$mon_string = "mtime:" . $r->filename;
		}

	}
 
	$r->warn( "monitor_handler 3 , monstring=$mon_string");
        my $reply_uri = $r->header_in( 'Reply-To' );
 
        if( !defined $reply_uri || !$reply_uri)
        {
		$r->warn( "--------BAD REQUEST -------------" );
		$r->warn( $r->method );
		$r->warn( $r->method_number );
		$r->warn( "--------BAD REQUEST -------------" );
                return BAD_REQUEST;
        }

 
        my ($mon_url,$rv) = add_subscription($r,$monitored_uri,$mon_string,$state,$reply_uri);
	if($rv == SUBSCRIBE_ERROR)
	{
		return SERVER_ERROR;
	}
 
	if( 
	   ($r->header_in('Accept') =~ /text\/html/)
	|| ($r->header_in('Accept') =~ /\*\/\*/)

	 )
	{
		my $msg = ($rv == SUBSCRIBE_OK) ? "You have been subscribed to the URL"
						: "You are already subscribed to the URL";
		$r->status(200);
        	$r->send_http_header("text/html");
		
		$r->print(qq{
		<html>
		<title>Subscribed</title>
		<body>
		$msg
		<a href="$monitored_uri">$monitored_uri</a>
		<br />
		<br />
		To edit or remove your subscription, visit the
		<a href="$mon_url">monitor page</a>
		</body>
		</html>
		});
	}
	else
	{
		$r->header_out('Content-type' => undef);
		$r->header_out('Content-Type' => undef);
        	$r->header_out("Location" => $mon_url );
		$r->status(201);
        	$r->send_http_header();
	}
 
        return OK;
}

sub moo
{
        my $r = shift;

	

        my $dir = $r->dir_config('MonitorDataDir');
	my $host = $r->header_in( 'Host' );
	my $mon_uri = 'http://' . $host . $r->uri();

	if($r->method eq "GET")
	{
	my %uris;
	my %monitors;

	open(LOCK,">$dir/lock") || die("unable to open $dir/lock, $!");
	flock(LOCK,1);	

	dbmopen(%monitors , "$dir/monitors", 0666) || die("unable to open $dir/monitors, $!");
	my $value = $monitors{$mon_uri};
	dbmclose(%monitors);
	close(LOCK);

	if(!defined $value)
	{
		return NOT_FOUND;
	}	


	my ($u,$re) = split( / / , $value);

        $r->send_http_header("text/html" );
	$r->print( qq{
	<html>
	<head>
	<title>Monitor $mon_uri</title>
	</head>
	<body>
	
	<p>
	<b>Monitor $mon_uri</b>
	</p>

	<p>Monitors: <a href="$u">$u</a><br />
	Reply-To: <a href="$re">$re</a>
	</p>
	<!--
	<p><b>Edit your daily notification period</b><br />
	<form method="POST">
	From <input type="text" size="2" /> o'clock until
	<input type="text" size="2" /> o'clock.
	<input value="Change" type="submit" />
	</form>
	</p>
	-->

	<form method="POST">
	<input type="hidden" name="method" value="DELETE" />
	<input value="Unsubscribe" type="submit" />
	</form>
	</body>
	</html>
	});
	return OK;

	}
	elsif($r->method eq "POST")
	{
		my %params = $r->content;
		return HTTP_METHOD_NOT_ALLOWED;
	}
	elsif($r->method eq "DELETE")
	{
	my %uris;
	my %monitors;
	my $uri_still_monitored = 0;

	open(LOCK,">$dir/lock") || die("unable to open $dir/lock, $!");
	flock(LOCK,2);	

	dbmopen(%monitors , "$dir/monitors", 0666) || die("unable to open $dir/monitors, $!");
	if(!exists($monitors{$mon_uri}))
	{
		dbmclose(%monitors);
		close(LOCK);
		return NOT_FOUND;
	}	
	my ($monitored_uri,$re) = split(/ / , $monitors{$mon_uri});
	delete $monitors{$mon_uri};
	foreach my $muri (keys %monitors)
	{
		die("XXXXX") if($mon_uri eq $muri);
		my $value = $monitors{$muri};
		my ($u,$re) = split(/ / , $value);
		if($u eq $monitored_uri)
		{
			$uri_still_monitored = 1;
			last;
		}
	}
	dbmclose(%monitors);
	if(!$uri_still_monitored)
	{
		dbmopen(%uris , "$dir/uris", 0666) || die("unable to open $dir/uris, $!");
		delete $uris{$monitored_uri};
		dbmclose(%uris);
	}
	close(LOCK);
	
        $r->send_http_header("text/html" );
	$r->print( qq{
	<html>
	<head>
	<title>Deleted Monitor $mon_uri</title>
	</head>
	<body>
	
	Monitor $mon_uri has been deleted. 
	</body>
	</html>
	});

	}

        return OK;
}

sub show_monitors
{
	my $r = shift;
	my %uris;
	my %monitors;
	my $dir = $r->dir_config('MonitorDataDir');
        my $host = $r->header_in( 'Host' );
        my $mon_uri = 'http://' . $host . $r->uri();

        $r->send_http_header("text/html" );
	$r->print( qq{
	<html>
	<head>
	<title>Monitors</title>
	</head>
	<body>
	});
	


	open(LOCK,">$dir/lock") || die("unable to open $dir/lock, $!");
	flock(LOCK,1);	

	dbmopen( %uris , "$dir/uris" , 0040) || die("unable to open $dir/uris, $!");	
	dbmopen( %monitors , "$dir/monitors" , 0040) || die("unable to open $dir/monitors, $!");	
	foreach my $uri ( keys %uris)
	{
		my $value = $uris{$uri};
		my ($u,$mon_string,$t,$state) = split(/ /,$value);
		$r->print(qq{<p><a href="$u">$u</a><br />\n});
		foreach my $muri (keys %monitors)
		{
			my $value = $monitors{$muri};
			#print "-- $value --\n";
			my ($u,$re) = split(/ / , $value);
			if($u eq $uri)
			{
				$r->print(qq{
				&nbsp;&nbsp;&nbsp;<a href="$muri">$muri</a>&nbsp;
				($re)  [$mon_string]<br />\n});	
			}
		}
		$r->print("</p>\n");
	}
	dbmclose(%uris);
	dbmclose(%monitors);

	close(LOCK);
}
 

sub add_subscription
{
        my ($r,$uri,$mon_string,$state,$reply_to) = @_;

        my $dir = $r->dir_config('MonitorDataDir');
        my $mon_prefix = $r->dir_config('MonitorUrlPrefix');

	my $monitor_url = $mon_prefix; 
	my %uris;
	my %monitors;


	open(LOCK,">$dir/lock") || die("unable to open $dir/lock, $!");
	flock(LOCK,2);	

	dbmopen( %uris , "$dir/uris", 0666) || die("unable to open $dir/uris, $!");	
	if(! exists $uris{$uri})
	{
		my $now = time();
		my $value = join(' ', ($uri,$mon_string,$now,$state) );
		$uris{$uri} = $value;
	}
	dbmclose(%uris);

	dbmopen( %monitors , "$dir/monitors", 0666) || die("unable to open $dir/monitors, $!");	
	foreach my $muri (keys %monitors)
	{
		my $value = $monitors{$muri};
		my ($u,$re) = split (/ /,$value);
		if( ($u eq $uri) && ($re eq $reply_to) )
		{
			
			dbmclose(%monitors);
			close(LOCK);
			return ($muri,SUBSCRIBE_ALREADY);
		}
	}
	my $id = time() . $$;	
	$monitor_url .= $id;
	$monitors{$monitor_url} = "$uri $reply_to";
	dbmclose(%monitors);
	close(LOCK);


	return ($monitor_url,SUBSCRIBE_OK);
}
 

sub get_monitor_code
{
	my ($r,$monitored_uri) = @_;
	return undef;
	return "checker";
}





sub SUBSCRIBE
{
	require LWP::UserAgent;
	@Apache::MONITOR::ISA = qw(LWP::UserAgent);

	my $ua = __PACKAGE__->new;
	
	my $args = @_ ? \@_ : \@ARGV;

	my ($url,$reply_to,$proxy) = @$args;
	$ua->proxy(['http'], $proxy ) if(defined $proxy);
	my $req = HTTP::Request->new('MONITOR' => $url );

	$req->header('Reply_To' => $reply_to );
	#$req->header('Accept' => 'text/plain' );
	my $res = $ua->request($req);

	if($res->is_success)
	{
		print $res->as_string();
		print "Monitor created at: ",$res->header('Location') , "\n";
	}
	else
	{
		print $res->as_string();
	}

}
sub UNSUBSCRIBE
{
	require LWP::UserAgent;
	@Apache::MONITOR::ISA = qw(LWP::UserAgent);

	my $ua = __PACKAGE__->new;
	
	my $args = @_ ? \@_ : \@ARGV;

	my ($mon_url) = @$args;
	my $req = HTTP::Request->new('DELETE' => $mon_url );

	my $res = $ua->request($req);

	if($res->is_success)
	{
		print $res->as_string();
		#print $res->content;
		print "Monitor deleted\n";
	}
	else
	{
		print $res->as_string();
	}

}

sub NOTIFY
{
	require LWP::UserAgent;
	@Apache::MONITOR::ISA = qw(LWP::UserAgent);
	my $ua = __PACKAGE__->new;
	my $args = @_ ? \@_ : \@ARGV;

	my ($dir) = @$args;

	my %uris;
	my %monitors;

	open(LOCK,">$dir/lock") || die("unable to open $dir/lock, $!");
	flock(LOCK,2);	

	dbmopen( %uris , "$dir/uris" , 0040) || die("unable to open $dir/uris, $!");	
	dbmopen( %monitors , "$dir/monitors" , 0040) || die("unable to open $dir/monitors, $!");	
	foreach my $monitored_uri ( keys %uris )
	{
		my $value = $uris{$monitored_uri};
		my ($u,$mon_string,$lastmod,$state) = split(/ /,$value);
		my $modified_time = $lastmod;
		#print "--$u $mon_string $lastmod\n";
		print "*--------------------------------------------------\n";

		if( $mon_string =~ /^apply:(.+)$/ )
		{
			# apply code
			my $code = $1; 
			require "/tmp/" . $code;
			$modified_time = $code->check($u);
		}
		elsif( $mon_string =~ /^mtime:(.+)$/ )
		{	
			my $filename = $1;	
			print "$monitored_uri: checking file mtime of $filename\n";	
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
                     	 $atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);
			$modified_time = $mtime;
		}
		else
		{
			my $old_checksum = $state;
			print "$monitored_uri: checking checksum via HTTP GET\n";	
			my ($checksum,$rv,$msg) = poll_to_checksum($monitored_uri);
			if($rv)
			{
				print "$monitored_uri: ",$msg, "\n";
				next;
			}
			print " ....old checksum $old_checksum\n";
			print " ....new checksum $checksum\n";
			if( $checksum != $old_checksum)
			{
				$modified_time = time();
				$state = $checksum;
			}
		}
	
		next unless ($modified_time > $lastmod);	

		print "...$monitored_uri has changed, getting monitors\n";

		# updating record with new lastmod

		$uris{$monitored_uri} = "$u $mon_string $modified_time $state";

		foreach my $muri (keys %monitors)
		{
			my $value = $monitors{$muri};
			my ($u,$re) = split(/ / , $value);
			next unless ($u eq $monitored_uri);

			#my $req = HTTP::Request->new('GET' => $monitored_uri);
			#my $res = $ua->request($req);
			#my $body;
			#if($res->is_success)
			#{
			#	$body = $res->content;
			#}
			#else
			#{
			#	$body = $res->as_string();
			#}
			#$req->header('Reply_To' => $reply_to );

			if( $re =~ /^mailto:(.*)$/ )
			{
				my $to = $1;
				open(MAIL,"|mail $to -s \"Resource $monitored_uri has changed\"");
				print MAIL "Resource state has changed at ". localtime($modified_time) ."\n";
				print MAIL "View the monitored resource: $monitored_uri\n";
				print MAIL "Edit your monitor: $muri\n";
				close(MAIL);
				print "   notified $re\n";	
			}
		}
		
	}
	dbmclose(%uris);
	dbmclose(%monitors);

	close(LOCK);

}
sub poll_to_checksum
{
	require LWP::UserAgent;
	@Apache::MONITOR::ISA = qw(LWP::UserAgent);
	my $ua = __PACKAGE__->new;
	my $args = @_ ? \@_ : \@ARGV;

	my ($uri) = @$args;

	my $req = HTTP::Request->new('GET' => $uri);
	my $res = $ua->request($req);
	if($res->is_success)
	{
		my $s = $res->content;
		$s =~ s/<meta[^>]+>//gi;
		my $cs = cksum($s);
		return ($cs,0,'');
	}
	else
	{
		return (0,1,'GET error');
	}
}

1;
__END__

=head1 NAME

Apache::MONITOR - Implementation of the HTTP MONITOR method

=head1 SYNOPSIS

=head1 DESCRIPTION

This module implements a MONITOR HTTP method, which adds notifications to the
World Wide Web.

=head1 CONFIGURATION

httpd.conf:

  PerlSetVar MonitorDataDir /home/httpd/monitors
  PerlSetVar MonitorUrlPrefix http://myserver/monitors/
 
  PerlPostReadRequestHandler Apache::MONITOR
  PerlHeaderParserHandler Apache::MONITOR::hp_handler
 
  <Location /monitors/>
    SetHandler perl-script
    PerlHandler Apache::MONITOR::moo
  </Location>


crontab:

  # check for changes every 30 minutes
  0,30 * * * * perl -MApache::MONITOR -e NOTIFY /home/httpd/monitors &>/dev/null


=head1 COMMANDLINE TOOLS

Subscribe:

  perl -MApache::MONITOR -e SUBSCRIBE http://www.mopo.de mailto:joe@the.org

Show all subscriptions:

  perl -MApache::MONITOR -e SHOW /path/to/monitors

Check for changes and notify:

  perl -MApache::MONITOR -e NOTIFY /path/to/monitors


=head2 EXPORT

=head1 AUTHOR

Jan Algermissen, algermissen@acm.org


=cut
