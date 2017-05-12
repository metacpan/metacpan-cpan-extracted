package Cikl::Smrt::Fetchers::Http;

use strict;
use warnings;
use Mouse;
use Cikl::Smrt::Fetcher;
use IO::File;
use LWP::Authen::Basic;
use File::Temp qw/tmpnam/;
use Cikl::Logging;
use Cikl;
extends 'Cikl::Smrt::Fetcher';

my $logger = get_logger();

use namespace::autoclean;
my @__tempfiles;
END {
  unlink($_) for(@__tempfiles);
  @__tempfiles = ();
}

our $AGENT = 'cikl-smrt/'.$Cikl::VERSION.' (cikl.org)';

use constant SCHEMES => qw/http https/;

has 'timeout' => (
  is => 'ro',
  isa => 'Num',
  default => 300,
  required => 1
);

has 'proxy' => (
  is => 'ro',
  #isa => 'Str',
  required => 0
);

has 'verify_tls' => (
  is => 'ro', 
  isa => 'Num',
  default => 1,
  required => 0
);

has 'feed_user' => (
  is => 'ro',
  isa => 'Str',
  required => 0
);

has 'feed_password' => (
  is => 'ro',
  isa => 'Str',
  required => 0
);

has 'mirror' => (
  is => 'ro',
  isa => 'Str',
  required => 0
);

sub schemes { 
  return SCHEMES;
}

sub fetch {
    my $self = shift;
    my $feedurl = $self->feedurl();
    
    unless($feedurl->scheme =~ /^http/) {
      die("Incorrect scheme: " . $feedurl->scheme());
    }
    
    # If a proxy server is set in the configuration use LWP::UserAgent
    # since LWPx::ParanoidAgent does not allow the use of proxies
    # We'll assume that the proxy is sane and handles timeouts and redirects and such appropriately.
    # LWPx::ParanoidAgent doesn't work well with Net-HTTP/TLS timeouts just yet
    my $ua;
    if (env_proxy() || $self->proxy() || $feedurl->scheme() eq 'https') {
        # setup the initial agent
        require LWP::UserAgent;
        $ua = LWP::UserAgent->new(agent => $AGENT);
        
        # pull from env_
        $ua->env_proxy();
        
        # if we override, specify
        my $proxy = $self->proxy();
        $ua->proxy(['http','https','ftp'], $proxy) if($proxy);
    } else {
        # we use this instead of ::UserAgent, it does better
        # overall timeout checking
        require LWPx::ParanoidAgent;
        $ua = LWPx::ParanoidAgent->new(agent => $AGENT);
    }
    
    $ua->timeout($self->timeout());
    
    # work-around for what appears to be a threading / race condition
    $ua->max_redirect(0) if($feedurl->scheme() eq 'https');

    if(defined($self->verify_tls == 0)) {
        $ua->ssl_opts(SSL_verify_mode => 'SSL_VERIFY_NONE');
    } else {
        $ua->ssl_opts(SSL_verify_mode => 'SSL_VERIFY_PEER');
    }

    if(defined($self->feed_user)){
      my $auth = LWP::Authen::Basic->auth_header($self->feed_user, $self->feed_password);
      $ua->default_header("Authentication" => $auth);
    }
    
    # work-around for a bug in LWP::UserAgent
    delete($ua->{'ssl_opts'}->{'verify_hostname'});

    my $filename;

    my $is_tempfile = 0;
    if(my $mirror = $self->mirror){
      $feedurl->path() =~ m/\/([a-zA-Z0-9._-]+)$/;
      $filename = $mirror.'/'.$1;
    } else {
      $filename = tmpnam();
      # Try to ensure that it gets unlinked when the process exits.
      push(@__tempfiles, $filename);
      $is_tempfile = 1;
    }

    $logger->debug("Saving response to $filename");

    die($filename.' isn\'t writeable by our user') if(-e $filename && !-w $filename);

    my $response = $ua->mirror($feedurl->as_string(), $filename);

    if( $response->is_error()){
      die('failed to get feed: '.$feedurl->as_string()."\n".$response->status_line());
    }
    $ua = undef;
    my $fh = IO::File->new($filename, 'r') or die($!);
    if ($is_tempfile == 1) {
      # This looks strange, but since we still have the filehandle open, it 
      # won't really disappear until the handle is closed.
      unlink($filename);
    }
    return($fh);
}

sub env_proxy {
    my ($self) = @_;
    require Encode;
    require Encode::Locale;
    my($k,$v);
    my $found = 0;
    while(($k, $v) = each %ENV) {
        if ($ENV{REQUEST_METHOD}) {
            # Need to be careful when called in the CGI environment, as
            # the HTTP_PROXY variable is under control of that other guy.
            next if $k =~ /^HTTP_/;
            $k = "HTTP_PROXY" if $k eq "CGI_HTTP_PROXY";
        }
        $k = lc($k);
        next unless $k =~ /^(.*)_proxy$/;
        $k = $1;
        unless($k eq 'no') {
            # Ignore random _proxy variables, allow only valid schemes
            next unless $k =~ /^$URI::scheme_re\z/;
            # Ignore xxx_proxy variables if xxx isn't a supported protocol
            next unless LWP::Protocol::implementor($k);
            $found = 1;
        }
    }
    return $found;
}

__PACKAGE__->meta->make_immutable;

1;
