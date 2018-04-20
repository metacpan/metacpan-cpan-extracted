#file:Apache2/AMFMobileCachingMemcached.pm; 
#-------------------------------- 

#
# Created by Idel Fuschini 
# Date: 01/08/10
# Site: http://www.apachemobilefilter.org
# Mail: idel.fuschini@gmail.com



package Apache2::AMFMobileCachingMemcached; 
  
  use strict; 
  use warnings; 
  use Apache2::AMFCommonLib ();
  
  use Apache2::RequestRec ();
  use Apache2::RequestUtil ();
  use Apache2::SubRequest ();
  use Apache2::Log;
  use Apache2::Filter ();
  use Apache2::Connection (); 
  use APR::Table (); 
  use LWP::Simple;
  use Cache::Memcached;
  use Apache2::Const -compile => qw(OK REDIRECT DECLINED);
  use IO::Uncompress::Unzip qw(unzip $UnzipError) ;
  use constant BUFF_LEN => 1024;
  use vars qw($VERSION);
  $VERSION= "4.33";;;
  #
  # Define the global environment
  #
  my $CommonLib = new Apache2::AMFCommonLib ();
  my $SetCacheTime="900";
  my $serverMemCache;
  my @Server;
  $CommonLib->printLog("---------------------------------------------------------------------------"); 
  $CommonLib->printLog("AMFMobileCachingMemcached Version $VERSION");
  if ($ENV{AMFMobileHome}) {
	  &loadConfigFile();
  } else {
	  $CommonLib->printLog("AMFMobileHome not exist.	Please set the variable AMFMobileHome into httpd.conf");
	  $CommonLib->printLog("Pre-Requisite: WURFLFilter must be activated");
	  ModPerl::Util::exit();
  }
  if ($ENV{ServerMemCached}) {
	$serverMemCache=$ENV{ServerMemCached};
	@Server = split(/,/, $ENV{ServerMemCached});
	$CommonLib->printLog("ServerMemCached is: $serverMemCache");
   } else {
	  $CommonLib->printLog("ServerMemCached is not setted. Please set the variable ServerMemCached into httpd.conf, example  \"PerlSetEnv ServerMemCached 10.10.10.10:11211\"");
	  ModPerl::Util::exit();      
  }
  
  my $memd = new Cache::Memcached {
    'debug' => 0,
    'compress_threshold' => 10_000,
    'enable_compress' => 1,
  };
  $memd->set_servers(\@Server);

sub loadConfigFile {
	my $dummy;
	my $carrier;
	my $nation;
	my $ip;
	my $row;
	my @rows;
	my $carriernetdownload="none";
	my $carrierurl;
	my $total_carrier_ip=0;
	my $ip2;
	
	$CommonLib->printLog("AMFCarrierDetection: Start read configuration from httpd.conf");
	if ($ENV{SetCacheTime}) {
		$SetCacheTime=$ENV{SetCacheTime};
		$CommonLib->printLog("SetCacheTime is: $SetCacheTime (seconds)");
	} else {
        $CommonLib->printLog("SetCacheTime is not setted. So, the default timeout is: $SetCacheTime seconds");
	}

	$CommonLib->printLog("Finish loading  parameter");
}
sub handler    {
    my $f = shift;              
    my $r = $f->r;              
    my $finfo = $r->finfo;       
    my $uri = $f->r->uri();
    my $s = $f->r->server;
    my $content_type=$f->r->content_type();
    my $hostname=$f->r->hostname();
    my $port=$f->r->get_server_port();
    my $id='null';
    my $query_string=$f->r->args;
    if ($query_string) {
    } else {
       $query_string = "";
    }
    $hostname="$hostname:$port";
    if ($f->r->pnotes('id')) {      
      	$id=$f->r->pnotes('id')
    } else { 
        $s->warn("AMF error - probably the AMFWURFLFilter is not started");
    }
    unless( $f->ctx ) { 
       $f->r->headers_out->unset('Content-Length'); 
       $f->ctx(1); 
    }
    my  $key="$hostname:$id:$uri:$query_string";
    my $page=$f->read(my $buf, BUFF_LEN);
    my $var=$memd->get($key);
    if ($var) {
        my $hash_dummy=$var;
        my %hash=%$hash_dummy;
        my $content_type = $hash{'content_type'};
        $buf = $hash{'page'};
    } else {
        my %hash=('content_type',$content_type,'page',$buf);
	    $memd->set($key,\%hash, time + $SetCacheTime); 
    }
    $f->r->content_type($content_type);
    #$f->r->headers_out->set("Content-Length"=>$buf);
    $f->print($buf);
    return Apache2::Const::OK; 
} 

1;


=head1 NAME

Apache2::AMFMobileCachingMemcached - This module has the scope to cache the static in content in different layout for mobile.

=head1 DESCRIPTION

This module has the scope to cache the static in content in different layout for mobile.

For more details: http://wiki.apachemobilefilter.org

=head1 AMF PROJECT SITE

http://www.apachemobilefilter.org

=head1 DOCUMENTATION

http://wiki.apachemobilefilter.org

Perl Module Documentation: http://wiki.apachemobilefilter.org/index.php/AMFMobileCaching

=head1 AUTHOR

Idel Fuschini (idel.fuschini [at] gmail [dot] com)

=head1 COPYRIGHT

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut