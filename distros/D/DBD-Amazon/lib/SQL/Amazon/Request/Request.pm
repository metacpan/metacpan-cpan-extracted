#
#   Copyright (c) 2005, Presicient Corp., USA
#
# Permission is granted to use this software according to the terms of the
# Artistic License, as specified in the Perl README file,
# with the exception that commercial redistribution, either 
# electronic or via physical media, as either a standalone package, 
# or incorporated into a third party product, requires prior 
# written approval of the author.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Presicient Corp. reserves the right to provide support for this software
# to individual sites under a separate (possibly fee-based)
# agreement.
#
#	History:
#
#		2005-Jan-27		D. Arnold
#			Coded.
#
package SQL::Amazon::Request::Request;

use LWP;
use IO::File;
use XML::Simple;
use DBI;

use strict;
our $last_time;

our %url_roots = (
'us', 'http://webservices.amazon.com/onca/xml?'
);
our %reqcache = ();

use constant AMZN_CACHE_TIME_LIMIT => 1800;

sub new {
	my $class = shift;
	my $obj = {};
	$obj->{_lwp} = LWP::UserAgent->new
		or return undef;
	$obj->{_lwp}->timeout(60);	
	$obj->{_lwp}->agent( 'Mozilla/4.0 (compatible; MSIE 5.12; Mac_PowerPC)' );
	$obj->{_lwp}->env_proxy;
	bless $obj, $class;
	return $obj;
}
sub populate_request {
	my ($obj, $subid, $locale, $stmt) = @_;
	$obj->{url_params}{SubscriptionId} = $subid;
	$obj->{_locale} = $locale ||= 'us';
	return $url_roots{$obj->{_locale}} ? $obj : undef;
}

sub send_request {
	my ($obj, $store, $reqids) = @_;
	$obj->{_warnmsg} = undef;
	$obj->{_errmsg} = undef;
	my $url_params = $obj->{url_params}; 
	my %reqhash = %$url_params;
	foreach (keys %$url_params) {
		delete $url_params->{$_}
			unless (defined($url_params->{$_}) &&
				($url_params->{$_} ne ''));
	}

	while (1) {
		my $currpage = $url_params->{ItemPage};
		last if ($currpage > $obj->{_max_pages});
		my ($cache_req, $lastpage) = $obj->check_cache;
		
		if ($cache_req) {
			DBI->trace_msg("[SQL::Amazon::Request::Request::send_request] Request satisfied from cache.\n", 3)
				if $ENV{DBD_AMZN_DEBUG};
			$reqids->{$cache_req} = 1;
			$obj->advance_request_page;
			$lastpage ? last : next;
		}
		my $dbgname = $ENV{DBD_AMZN_SRC};

		if ($dbgname) {
			$dbgname .= $url_params->{ResponseGroup} . 
				'/reqno' . $obj->{_reqno} . 'page' . $currpage . '.xml'
				if (substr($dbgname, -1, 1) eq '/');
		}
		sleep 1
			while (defined($last_time) && (time() - $last_time == 0));
		my $xml;
		if ($dbgname && -e $dbgname) {
			DBI->trace_msg("[SQL::Amazon::Request::Request::send_request] Loading XML from $dbgname.\n", 3)
				if $ENV{DBD_AMZN_DEBUG};

			eval { $xml = XMLin($dbgname); };
			if ($@) {
				print STDERR "Can't read local version of $dbgname: $@\n";
			}
		}

		unless (defined($xml)) {
			if ($ENV{DBD_AMZN_DEBUG}) {
				my $tracemsg = '';
				$tracemsg .= "$_=$url_params->{$_}&"
					foreach (keys %$url_params);
				chop $tracemsg;
				DBI->trace_msg("[SQL::Amazon::Request::Request::send_request] Posting ECS request:\n$tracemsg\n", 3);
			}

			my $resp = $obj->{_lwp}->post($url_roots{$obj->{_locale}}, $url_params);
	
			if ($dbgname && (! -e $dbgname)) {
				open(XMLF, ">$dbgname") || die $!;
				print XMLF $resp->decoded_content;
				close XMLF;
			}
		
			$obj->{_errstr} = 'Amazon ECS request failed: Unknown reason.',
			return undef
				unless $resp;

			$obj->{_errstr} = 'Amazon ECS request failed: ' . $resp->status_line,
			return undef
				unless $resp->is_success;
			$xml = XMLin($resp->decoded_content);
		}
	
		$obj->{_errstr} = 'Unable to parse Amazon ECS response.',
		return undef 
			unless $xml;
		$last_time = time();
		return undef
			if $obj->has_errors($xml);
		last
			unless $obj->process_results($xml, $store, $reqids);
	}
	$obj->{url_params} = \%reqhash;
	return $obj;		
}
sub check_cache {
	my $obj = shift;
	
	my $url_params = $obj->{url_params};
	
	my @req = ();
	push @req, $_ . '=' . $url_params->{$_}
		foreach (sort keys %$url_params);
	my $req = join('&', @req);

	return (undef, undef)
		unless $reqcache{$req};
	
	delete $reqcache{$req},
	return (undef, undef)
		if ($reqcache{$req}[2] < time());
	$reqcache{$req}[2] = time() + AMZN_CACHE_TIME_LIMIT;
}
sub add_to_cache {
	my ($obj, $reqid, $lastpage) = @_;
	
	my $url_params = $obj->{url_params};
	
	my @req = ();
	push @req, $_ . '=' . $url_params->{$_}
		foreach (sort keys %$url_params);

	my $req = join('&', @req);
	
	$reqcache{$req} = [ $reqid, $lastpage, time() + AMZN_CACHE_TIME_LIMIT ];
	return $obj;
}

sub errstr { return shift->{_errstr}; }

sub warnstr { return shift->{_warnstr}; }
sub equals {
	my ($obj, $request) = @_;
	
	return undef 
		unless (ref $obj eq ref $request);
	my $myparms = $obj->{url_params};
	my $otherparms = $request->{url_params};
	foreach (%$myparms) {
		return undef 
			unless ($otherparms->{$_} &&
				($myparms->{$_} eq $otherparms->{$_}));
	}
	foreach (%$otherparms) {
		return undef 
			unless ($myparms->{$_} &&
				($myparms->{$_} eq $otherparms->{$_}));
	}
	return 1;
}

sub has_errors {
	my ($obj, $xml) = @_;
	return undef;
}
sub more_results {
	my ($obj, $xml) = @_;
	return undef;
}
sub process_results {
	my ($obj, $xml, $engine, $reqids) = @_;
	return 1;
}
sub advance_request_page {
	my $obj = shift;
	return $obj;
}

1;
