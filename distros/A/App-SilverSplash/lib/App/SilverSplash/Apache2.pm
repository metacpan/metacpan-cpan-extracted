package App::SilverSplash::Apache2;

use strict;
use warnings;

use constant DEBUG => $ENV{SL_DEBUG} || 0;

use base 'App::SilverSplash';

use Apache2::Const -compile => qw( NOT_FOUND OK REDIRECT SERVER_ERROR DECLINED
  AUTH_REQUIRED HTTP_SERVICE_UNAVAILABLE DONE
  M_GET M_POST HTTP_METHOD_NOT_ALLOWED );

use Data::Dumper qw(Dumper);

use Apache2::Request        ();
use Apache2::RequestRec     ();
use Apache2::Connection     ();
use Apache2::ConnectionUtil ();
use Apache2::Log            ();
use Apache2::Response       ();
use Apache2::RequestUtil    ();
use Apache2::URI            ();
use APR::Table              ();

use Config::SL  ();
use Template    ();
use URI::Escape ();
use Business::PayPal;

our $Config = Config::SL->new;

our $Template =
  Template->new( INCLUDE_PATH => $Config->sl_httpd_root . '/htdocs/sl/' );

# bypass the iphone captive portal detector

sub iphone_check {
    my ( $class, $r ) = @_;

    my $ua = $r->headers_in->{'user-agent'};
    if ( defined $ua && ( substr( $ua, 0, 21 ) eq 'CaptiveNetworkSupport' ) ) {

        $r->set_handlers( PerlResponseHandler => undef );
        return Apache2::Const::OK;
    }
    else {
        return Apache2::Const::OK;
    }
}

# paypal ipn handler

sub ipnvalidate {
    my ( $class, $r ) = @_;

    my $req = Apache2::Request->new($r);

    # build cgi compatible request hash
    my @param = $req->param;
    my %q;
    foreach my $key (@param) {
        $q{$key} = $req->param($key);
    }

    $r->log->debug( "request dump is " . Dumper( \%q ) ) if DEBUG;

    my $id = $q{custom};
    my $paypal = Business::PayPal->new( id => $id );
    my ( $txnstatus, $reason ) = $paypal->ipnvalidate( \%q );
    unless ($txnstatus) {
        $r->log->error("PayPal failed: $reason");
        return Apache2::Const::SERVER_ERROR;
    }

    # check to see if we can find a mac address for this paypal_id
    my $found = $class->get("paypal_id|$id");
    my ( $mac, $ip ) = split( /\|/, $found );
    my $added = App::SilverSplash::IPTables->add_to_paid_chain( $mac, $ip );

    return Apache2::Const::OK;
}

# base level request handler

sub handler {
    my ( $class, $r ) = @_;

    my $ip = $r->connection->remote_ip;
    $r->log->debug("$$ new request ip $ip") if DEBUG;
    $r->log->debug( "request: " . $r->as_string ) if DEBUG;

    # "Thou shalt not pass!" - Gandalf
    my $mac = $class->mac_from_ip($ip);
    unless ($mac) {
        $r->no_cache(1);
        $r->content_type('text/plain');
        $r->print(
"Please renew your DHCP lease, or reboot your computer to get a valid DHCP lease"
        );
        return Apache2::Const::OK;
    }

    return Apache2::Const::HTTP_METHOD_NOT_ALLOWED
      if ( $r->header_only or ( $r->method_number != Apache2::Const::M_GET ) );

    return Apache2::Const::HTTP_SERVICE_UNAVAILABLE
      unless $r->headers_in->{'user-agent'};

    my $dest_url = $r->construct_url( $r->unparsed_uri );

    # check to see if this mac has been authenticated already
    my $authed = $class->check_auth( $mac, $ip );

    if ($authed) {

        # this is a known mac, go on to the web
        $r->log->debug("$$ valid mac $mac, redirect to $dest_url") if DEBUG;
        $r->headers_out->set( Location => $dest_url );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;

    }

    my %tmpl = (
        perlbal  => 'http://' . $class->lan_ip . ':' . $Config->sl_perlbal_port,
        cdn_host => $Config->sl_cdn_host,
        mac      => URI::Escape::uri_escape($mac),
        url      => URI::Escape::uri_escape($dest_url),
        cp_mac   => URI::Escape::uri_escape( $class->wan_mac ),
        provider_href => $Config->sl_account_website,
        provider_logo => $Config->sl_account_logo,
    );

    $r->content_type('text/html; charset=UTF-8');
    $r->no_cache(1);
    $r->rflush;

    my $output;
    $Template->process( 'splash.tmpl', \%tmpl, \$output )
      || die $Template->error;
    $r->print($output);

    return Apache2::Const::OK;
}

# authentication requests for free service

sub free {
    my ( $class, $r ) = @_;

    my $ip  = $r->connection->remote_ip;
    my $mac = $class->mac_from_ip($ip);
    return Apache2::Const::NOT_FOUND unless $mac;

    my $req = Apache2::Request->new($r);
    my $url = $req->param('url');

    # serve the page or process the request
    if ( $r->method_number == Apache2::Const::M_GET ) {

        my %tmpl = (
            perlbal => 'http://'
              . $class->lan_ip . ':'
              . $Config->sl_perlbal_port,
            cdn_host => $Config->sl_cdn_host,
            mac      => URI::Escape::uri_escape($mac),
            url => $url,    #URI::Escape::uri_escape($url),
            cp_mac        => URI::Escape::uri_escape( $class->wan_mac ),
            provider_href => $Config->sl_account_website,
            provider_logo => $Config->sl_account_logo,
        );

        my $output;
        $Template->process( 'free.tmpl', \%tmpl, \$output )
          || die $Template->error;
        $r->content_type('text/html; charset=UTF-8');
        $r->no_cache(1);
        $r->rflush;
        $r->print($output);
        return Apache2::Const::OK;

    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        my $terms = $req->param('terms');

        unless ($terms) {
            $r->method_number(Apache2::Const::M_GET);
            return $class->free($r);
        }

        # they clicked yes, authenticate
        my $added = App::SilverSplash::IPTables->add_to_ads_chain( $mac, $ip );

        unless ($added) {

            $r->log->error("$$ error adding mac $mac to ads chain: $@");
            return Apache2::Const::SERVER_ERROR;
        }

        my $location =
          $class->make_post_url( $Config->sl_splash_href,
            URI::Escape::uri_escape($url) );

        $r->headers_out->set( Location => $location );
        $r->no_cache(1);
        return Apache2::Const::REDIRECT;
    }
}

sub paid {
    my ( $class, $r ) = @_;

    my $ip  = $r->connection->remote_ip;
    my $mac = $class->mac_from_ip($ip);
    return Apache2::Const::NOT_FOUND unless $mac;

    my $req = Apache2::Request->new($r);
    my $url = $req->param('url');

    # serve the page or process the request
    if ( $r->method_number == Apache2::Const::M_GET ) {

        my $p  = Business::PayPal->new;
        my $id = $p->id;
        my $b  = $p->button(
            'item_number' => 1,
            'business'    => $Config->sl_paypal_account,
            'item_name'   => 'airCloud WiFi Purchase',
            'notify_url'  => 'http://'
              . $Config->sl_dmz_listen
              . "/ipn_validate?url=$url&id=$id",
            'return'        => $Config->sl_splash_href,
            'cancel_return' => 'http://'
              . $class->lan_ip
              . ":9999/paid?url=$url",
            'amount'       => '0.05',
            'quantity'     => 1,
            'button_image' => CGI::image_button(
                -name => 'submit',
                -src =>
                  'http://s1.slwifi.com/images/buttons/3_hour_service.png',
                -alt => 'Make payments with PayPal',
            ),
        );

        $class->set( "paypal_id|$id" => "$mac|$ip" );

        my %tmpl = (
            perlbal => 'http://'
              . $class->lan_ip . ':'
              . $Config->sl_perlbal_port,
            cdn_host => $Config->sl_cdn_host,
            mac      => URI::Escape::uri_escape($mac),
            url => $url,    #URI::Escape::uri_escape($url),
            cp_mac        => URI::Escape::uri_escape( $class->wan_mac ),
            provider_href => $Config->sl_account_website,
            provider_logo => $Config->sl_account_logo,
            button        => $b,
        );

        my $output;
        $Template->process( 'paid.tmpl', \%tmpl, \$output )
          || die $Template->error;
        $r->content_type('text/html; charset=UTF-8');
        $r->no_cache(1);
        $r->rflush;
        $r->print($output);
        return Apache2::Const::OK;

    }
    elsif ( $r->method_number == Apache2::Const::M_POST ) {

        my $terms = $req->param('terms');

        unless ($terms) {
            $r->method_number(Apache2::Const::M_GET);
            return $class->free($r);
        }

        # they clicked yes, authenticate

        my $added = App::SilverSplash::IPTables->add_to_paid_chain( $mac, $ip );

        unless ($added) {

            $r->log->error("$$ error adding mac $mac to paid chain: $@");
            return Apache2::Const::SERVER_ERROR;
        }
    }
    $mac = URI::Escape::uri_escape($mac);
    $url = URI::Escape::uri_escape($url);

    # else we have an authenticated user
    my $location = $class->make_post_url( $Config->sl_splash_href, $url );
    $r->headers_out->set( Location => $location );
    $r->no_cache(1);
    return Apache2::Const::REDIRECT;
}

sub make_post_url {
    my ( $class, $splash_url, $dest_url ) = @_;

    $dest_url = URI::Escape::uri_escape($dest_url);
    my $separator = ( $splash_url =~ m/\?/ ) ? '&' : '?';

    my $location = $splash_url . $separator . "url=$dest_url";

    return $location;
}

1;

__END__


=cut

    # throttling code

    my $c = $r->connection;
    if (my $attempts = $c->pnotes($c->remote_ip)) {
	my $count = $attempts->{count};
	my @times = @{$attempts->{times}};
	my $idx;
	if ($#times > 9) {
		$count = 10;
		$idx=$#times-$count;
	} else {
		$idx=0;
	}
	my $total_time = $times[$#times] - $times[$idx];

	push @{$attempts->{times}}, time();
	$attempts->{count}++;

	# keep a three deep history of previous urls, first_url is the first one seen
	if (exists $attempts->{middle_url}) {
		$attempts->{bottom_url} = $attempts->{middle_url};
	}
	$attempts->{middle_url} = $attempts->{top_url};
	$attempts->{top_url} = $dest_url;

	$c->pnotes($c->remote_ip => $attempts);
	if ($total_time != 0) {

		# three of the same urls in a row is a violation

		if (exists $attempts->{bottom_url}) {

			if (($attempts->{bottom_url} eq $attempts->{middle_url}) &&
		   	    ($attempts->{middle_url} eq $attempts->{top_url})) {

			    	# three requests the same in less than 5 seconds means 503
				if (($times[$#times] - $times[$#times-2]) < 5) {

					$r->log->error("triple rate violation ip $ip, mac $mac, url $dest_url");
					return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
				}
			}
		}

		my $rate = ($count / $total_time);
		$r->log->debug("throttle check mac $mac, ip $ip, count $count, time $total_time, rate $rate") if DEBUG;

		if (($count > $Min_count) && ($rate > $Max_rate)) {

			$r->log->error("rate violation ip $ip, mac $mac, time $total_time, count $count, rate $rate, url $dest_url");
			return Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
		}
	}
    } else {
	  my %attempts = ( 'count' => 1, 'times' => [ time() ], 'top_url' => $dest_url );
	  $r->log->debug("setting new limit check for ip $ip, count 1, time " . time()) if DEBUG;
  	  $c->pnotes($c->remote_ip => \%attempts);
   }

=cut


