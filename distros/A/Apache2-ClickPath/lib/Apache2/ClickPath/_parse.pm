package Apache2::ClickPath::_parse;

use strict;
use MIME::Base64 ();
use Digest::MD5 ();
use LWP::UserAgent ();
use HTTP::Response ();

our $VERSION = '1.9';

{
  package Apache2::ClickPath::_parse::UA;
  use base 'LWP::UserAgent';

  sub get_basic_credentials {
    my ($I, $realm, $uri, $isproxy)=@_;
    if( $isproxy ) {
      return @ENV{qw{HTTP_PROXY_USERNAME HTTP_PROXY_PASSWORD}};
    } else {
      return @ENV{qw{HTTP_USERNAME HTTP_PASSWORD}};
    }
  }
}

sub Secret {
  my $arg=shift;

  die "ERROR: ClickPathSecret URL: please specify a http, https, file or data URL\n"
    unless( $arg=~/^(https?|file|data):/ );

  my $ua=Apache2::ClickPath::_parse::UA->new;

  local @ENV{qw{HTTPS_PROXY HTTPS_PROXY_USERNAME HTTPS_PROXY_PASSWORD
		HTTPS_DEBUG HTTPS_VERSION HTTPS_CERT_FILE HTTPS_KEY_FILE
		HTTPS_CA_FILE HTTPS_CA_DIR HTTPS_PKCS12_FILE
		HTTPS_PKCS12_PASSWORD
		HTTP_PROXY HTTP_PROXY_USERNAME HTTP_PROXY_PASSWORD
		HTTP_USERNAME HTTP_PASSWORD}};

  if( $arg=~s#^(https?://)((?:\\.|[^\\@])+)@#$1# ) {
    my @auth=split /(?<!\\):/, $2, 3;
    if( length $auth[0] and length $auth[1] ) {
      @ENV{qw{HTTP_USERNAME HTTP_PASSWORD}}=map {s!\\(.)!$1!g; $_} @auth[0,1];
    }
    foreach my $el (split /(?<!\\);/, $auth[2]) {
      $el=~s!\\(.)!$1!g;
      if( $el=~s/https_proxy=//i ) {
	$ENV{HTTPS_PROXY}=$el;
      } elsif( $el=~s/https_proxy_username=//i ) {
	$ENV{HTTPS_PROXY_USERNAME}=$el;
      } elsif( $el=~s/https_proxy_password=//i ) {
	$ENV{HTTPS_PROXY_PASSWORD}=$el;
      } elsif( $el=~s/https_version=//i ) {
	$ENV{HTTPS_VERSION}=$el;
      } elsif( $el=~s/https_cert_file=//i ) {
	$ENV{HTTPS_CERT_FILE}=$el;
      } elsif( $el=~s/https_key_file=//i ) {
	$ENV{HTTPS_KEY_FILE}=$el;
      } elsif( $el=~s/https_ca_file=//i ) {
	$ENV{HTTPS_CA_FILE}=$el;
      } elsif( $el=~s/https_ca_dir=//i ) {
	$ENV{HTTPS_CA_DIR}=$el;
      } elsif( $el=~s/https_pkcs12_file=//i ) {
	$ENV{HTTPS_PKCS12_FILE}=$el;
      } elsif( $el=~s/https_pkcs12_password=//i ) {
	$ENV{HTTPS_PKCS12_PASSWORD}=$el;
      } elsif( $el=~s/http_proxy=//i ) {
	$ua->proxy( http=>$el );
      } elsif( $el=~s/http_proxy_username=//i ) {
	$ENV{HTTP_PROXY_USERNAME}=$el;
      } elsif( $el=~s/http_proxy_password=//i ) {
	$ENV{HTTP_PROXY_PASSWORD}=$el;
      }
    }
  }
  $arg=~s!\\(.)!$1!g if( $arg=~m#^https?://# );

  my $resp=$ua->get( $arg );

  if( $resp->code==200 ) {
    $arg=$resp->content;
    if( $arg=~s/^binary:// ) {
      # blowfish keys are up to 56 bytes long
      $arg=substr( $arg, 0, 56 ) if( length($arg)>56 );
    } elsif( $arg=~s/^hex:// ) {
      $arg=pack( 'H*', $arg );
      $arg=substr( $arg, 0, 56 ) if( length($arg)>56 );
    } elsif( $arg=~s/^password:// ) {
      $arg=Digest::MD5::md5( $arg );
    } else {
      $arg=Digest::MD5::md5( $arg );
    }
    return $arg;
  } else {
    die "ERROR: ClickPathSecret: Cannot fetch secret from $arg\n";
  }
}

sub MachineTable {
  my $conf=shift;
  my $t={};
  my $r={};
  my $i=0;
  foreach my $line (split /\r?\n/, $conf) {
    next if( $line=~/^\s*#/ ); 	# skip comments
    $i++;
    my @l=$line=~/\s*(\S+)(?:\s+(\w+)(?:\s+(.+))?)?/;
    $l[2]=~s/\s*$// if( defined $l[2] ); # strip trailing spaces
    if( @l ) {
      $l[1]=$i unless( defined $l[1] );
      if( $l[0]=~/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ and
	  $1<256 and $2<256 and $3<256 and $4<256 ) {
	$t->{$l[0]}=[@l[1,2]];
	$r->{$l[1]}=[@l[0,2]];
      } else {
	my @ip;
	(undef, undef, undef, undef, @ip)=gethostbyname( $l[0] );
	warn "WARNING: Cannot resolve $l[0] -- ignoring\n" unless( @ip );
	$r->{$l[1]}=[sprintf( '%vd', $ip[0] ), $l[2]];
	foreach my $ip (@ip) {
	  $t->{sprintf '%vd', $ip}=[@l[1,2]];
	}
      }
    }
  }
  return $t, $r;
}

sub UAExceptions {
  my $conf=shift;
  my $a=[];
  foreach my $line (split /\r?\n/, $conf) {
    if( $line=~/^\s*(\w+):?\s+(.+?)\s*$/ ) {
      push @{$a}, [$1, qr/$2/];
    }
  }
  return $a;
}

sub FriendlySessions {
  my $conf=shift;
  my $t={};
  my $r={};

  foreach my $l (split /\r?\n/, $conf) {

    next unless( $l=~/^\s*(\S+)\s+	# $1: friendly REMOTE_HOST
                      (			# $2: list of "uri( number )" or
                       (?:		#     "param( name )" statements
		        (?:uri|param)\s*
		        \(
		          \s*\w+\s*
                        \)\s*
                       )+
                      )
                      (?:\s*(\w+))?	# $3: opt. name, default=REMOTE_HOST
                     /x );

    my ($rem_host, $stmt_list, $name)=($1, $2, $3);
    $name=$rem_host unless( defined $name );

    my @stmts;
    while( $stmt_list=~/(uri|param)\s*\(\s*(\w+)\s*\)/g ) {
      push @stmts, [$1, $2];
    }

    $t->{$rem_host}=[[@stmts], $name];
    $r->{$name}=$rem_host;
  }

  return $t, $r;
}

1;
