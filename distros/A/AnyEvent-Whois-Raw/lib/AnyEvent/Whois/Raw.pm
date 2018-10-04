package AnyEvent::Whois::Raw;

use base 'Exporter';
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::HTTP;
use strict;
no warnings 'redefine';

our $VERSION = '0.08';
our @EXPORT = qw(whois get_whois);
our $stash;

BEGIN {
	sub Net::Whois::Raw::smart_eval(&) {
		my @rv = eval {
			$_[0]->();
		};
		if ($@ && $@ =~ /^Call me later/) {
			die $@;
		}
		
		return @rv;
	}
	
	sub require_hook {
		my ($self, $fname) = @_;
		
		return if $fname ne 'Net/Whois/Raw.pm';
		for my $i (1..$#INC) {
			if (-e (my $tname = $INC[$i] . '/Net/Whois/Raw.pm')) {
				open(my $fh, $tname) or next;
				return ($fh, \&eval_filter);
			}
		}
		return;
	}
	
	sub eval_filter {
		return 0 if $_ eq '';
		s/\beval\s*{/smart_eval{/;
		return 1;
	}
	
	unshift @INC, \&require_hook;
	require Net::Whois::Raw;
}

sub _extract_known_params {
	my $args = shift;
	my %known_params = (
		timeout => 1,
		on_prepare => 1,
	);
	
	my %params;
	eval {
		for my $i (-2, -2) {
			if (exists($known_params{$args->[$i-1]})) {
				$params{$args->[$i-1]} = $args->[$i];
				delete $known_params{$args->[$i-1]};
				splice @$args, $i-1, 2;
			}
			else {
				last;
			}
		}
	};
	
	return \%params;
}

sub whois {
	local $stash = {
		caller => \&_whois,
		params => _extract_known_params(\@_),
		args => [@_],
	};
	
	&_whois;
}

sub _whois {
	my $cb = pop;
	
	my ($res_text, $res_srv);
	eval {
		($res_text, $res_srv) = Net::Whois::Raw::whois(@_);
	};
	if (!$@) {
		$cb->($res_text, $res_srv);
	}
	elsif ($@ !~ /^Call me later/) {
		$cb->('', $@);
	}
}

sub get_whois {
	local $stash = {
		caller => \&_get_whois,
		params => _extract_known_params(\@_),
		args => [@_],
	};
	
	&_get_whois;
}

sub _get_whois {
	my $cb = pop;
	
	my ($res_text, $res_srv);
	eval {
		($res_text, $res_srv) = Net::Whois::Raw::get_whois(@_);
	};
	if (!$@) {
		$cb->($res_text, $res_srv);
	}
	elsif ($@ !~ /^Call me later/) {
		$cb->('', $@);
	}
}

sub Net::Whois::Raw::whois_query {
	my $call = $stash->{calls}{whois_query}++;
	if ($call <= $#{$stash->{results}{whois_query}}) {
		return $stash->{results}{whois_query}[$call] || die $stash->{errors}{whois_query}[$call], "\n";
	}
	
	whois_query_ae(@_);
	die "Call me later";
}

sub whois_query_ae {
	my ($dom, $srv_and_port, $is_ns) = @_;

	
	my $whoisquery = Net::Whois::Raw::Common::get_real_whois_query($dom, $srv_and_port, $is_ns);
	my $stash_ref = $stash;

	my ($srv, $port) = split /:/, $srv_and_port;
	
	tcp_connect $srv, $port || 43, sub {
		my $fh = shift;
		unless ($fh) {
			local $stash = $stash_ref;
			$stash->{calls}{whois_query} = 0;
			my $i = push @{$stash->{results}{whois_query}}, undef;
			$stash->{errors}{whois_query}[$i-1] = "Connection to $srv failed: $!";
			$stash->{caller}->(@{$stash->{args}});
			return;
		}
		
		my @lines;
		my $handle;
		my $timer = AnyEvent->timer(
			after => exists $stash_ref->{params}{timeout} ?
					$stash_ref->{params}{timeout} :
					$Net::Whois::Raw::TIMEOUT||30,
			cb => sub {
				if ($handle && !$handle->destroyed) {
					$handle->destroy();
					local $stash = $stash_ref;
					$stash->{calls}{whois_query} = 0;
					my $i = push @{$stash->{results}{whois_query}}, undef;
					$stash->{errors}{whois_query}[$i-1] = "Connection to $srv timed out";
					$stash->{caller}->(@{$stash->{args}});
				}
			}
		);
		$handle = AnyEvent::Handle->new(
			fh => $fh,
			on_read => sub {
				my @l = split /(?<=\n)/, $_[0]->{rbuf};
				if (@lines && substr($lines[-1], -1) ne "\n") {
					$lines[-1] .= shift(@l);
				}
				push @lines, @l;
				$_[0]->{rbuf} = '';
			},
			on_error => sub {
				undef $timer;
				$handle->destroy();
				local $stash = $stash_ref;
				$stash->{calls}{whois_query} = 0;
				my $i = push @{$stash->{results}{whois_query}}, undef;
				$stash->{errors}{whois_query}[$i-1] = "Read error from $srv: $!";
				$stash->{caller}->(@{$stash->{args}});
			},
			on_eof => sub {
				undef $timer;
				local $stash = $stash_ref;
				$handle->destroy();
				$stash->{calls}{whois_query} = 0;
				push @{$stash->{results}{whois_query}}, \@lines;
				$stash->{caller}->(@{$stash->{args}});
			}
		);
		
		$handle->push_write($whoisquery."\015\012");
	}, sub {
		my $fh = shift;
		local $stash = $stash_ref;
		_sock_prepare_cb($fh, $srv);
	};
}

sub _sock_prepare_cb {
	my ($fh, $srv) = @_;
	
	my $sockname = getsockname($fh);
	my $timeout = $Net::Whois::Raw::TIMEOUT||30;
	
	if (exists $stash->{params}{on_prepare}) {
		$timeout = $stash->{params}{on_prepare}->($fh);
	}
	
	my $rotate_reference = eval { Net::Whois::Raw::get_ips_for_query($srv) };
	
	if (!$rotate_reference && @Net::Whois::Raw::SRC_IPS && $sockname eq getsockname($fh)) {
		# we have ip and there was no bind request in on_prepare callback
		$rotate_reference = \@Net::Whois::Raw::SRC_IPS;
	}
	
	if ($rotate_reference) {
		my $ip = shift @$rotate_reference;
		bind $fh, AnyEvent::Socket::pack_sockaddr(0, parse_address($ip));
		push @$rotate_reference, $ip; # rotate ips
	}
	
	return exists $stash->{params}{timeout} ?
		$stash->{params}{timeout} :
		$timeout;
}

sub Net::Whois::Raw::www_whois_query {
	my $call = $stash->{calls}{www_whois_query}++;
	if ($call <= $#{$stash->{results}{www_whois_query}}) {
		return $stash->{results}{www_whois_query}[$call];
	}
	
	www_whois_query_ae(@_);
	die "Call me later";
}

sub www_whois_query_ae {
	my ($dom) = (lc shift);
	
	my ($resp, $url);
	my ($name, $tld) = Net::Whois::Raw::Common::split_domain( $dom );
	my @http_query_urls = @{Net::Whois::Raw::Common::get_http_query_url($dom)};
	
	www_whois_query_ae_request(\@http_query_urls, $tld, $dom);
}

sub www_whois_query_ae_request {
	my ($urls, $tld, $dom) = @_;
	
	my $qurl = shift @$urls;
	unless ($qurl) {
		push @{$stash->{results}{www_whois_query}}, undef;
		$stash->{calls}{www_whois_query} = 0;
		$stash->{caller}->(@{$stash->{args}});
		return;
	}
	
	my $referer = delete $qurl->{form}{referer} if $qurl->{form} && defined $qurl->{form}{referer};
	my $method = ( $qurl->{form} && scalar(keys %{$qurl->{form}}) ) ? 'POST' : 'GET';
	my $stash_ref = $stash;
	
	my $cb = sub {
		my ($resp, $headers) = @_;
		local $stash = $stash_ref;
		
		if (!$resp || $headers->{Status} > 299) {
			www_whois_query_ae_request($urls, $tld, $dom);
		}
		else {
			chomp $resp;
			$resp = Net::Whois::Raw::Common::parse_www_content($resp, $tld, $qurl->{url}, $Net::Whois::Raw::CHECK_EXCEED);
			push @{$stash->{results}{www_whois_query}}, $resp;
			$stash->{calls}{www_whois_query} = 0;
			$stash->{caller}->(@{$stash->{args}});
		}
	};
	
	my $headers = {Referer => $referer};
	my @params;
	push @params, on_prepare => sub { 
		my $fh = shift;
		local $stash = $stash_ref;
		_sock_prepare_cb($fh, 'www_whois');
	};
	
	if (exists $stash->{params}{timeout}) {
		push @params, timeout => $stash->{params}{timeout};
	}
	
	if ($method eq 'POST') {
		require URI::URL;
		
		my $curl = URI::URL->new("http:");
		$curl->query_form( %{$qurl->{form}} );
		http_post $qurl->{url}, $curl->equery, headers => $headers, @params, $cb;
	}
	else {
		http_get $qurl->{url}, headers => $headers,  @params, $cb;
	}
}

1;

__END__

How Net::Whois::Raw works:
whois
	get_whois
		get_all_whois  __
		|                \
		recursive_whois   www_whois_query
		|                 [BLOCKING]  
		whois_query
		[BLOCKING]        

There are two blocking functions.

What we do:
First of all redefine two blocking functions to non-blocking AnyEvent equivalents.
Now when get_all_whois will call whois_query or www_whois_query our AnyEvent
equivalents will be started. But when AnyEvent based function called result not ready
yet and we should interrupt get_all_whois. We do it using die("Call me later").
_whois and _get_whois ready to receive exception, they uses eval to catch it and calls
callback only if there was no exceptions. When result from AnyEvent based function becomes
ready it saves result and calls _whois or _get_whois again with same arguments as before interrupt.
So, now get_all_whois will not block because result already ready. Net::Whois::Raw::whois() or
Net::Whois::Raw::get_whois() will return without exceptions and so, callback will be called.
To store current state we are using localized stash.
recursive_whois() has one problem, it catches exceptions and our die("Call me later") will not interrupt
it. We using require hook to workaround it. We replace eval with our
defined smart_eval, which will rethrow exception if it was our exception.

=pod

=head1 NAME

AnyEvent::Whois::Raw - Non-blocking wrapper for Net::Whois::Raw

=head1 SYNOPSIS

  use AnyEvent::Whois::Raw;
  
  $Net::Whois::Raw::CHECK_FAIL = 1;
  
  whois 'google.com', timeout => 10, sub {
    my $data = shift;
    if ($data) {
      my $srv = shift;
      print "$data from $srv\n";
    }
    elsif (! defined $data) {
      my $srv = shift;
      print "no information for domain on $srv found";
    }
    else {
      my $reason = shift;
      print "whois error: $reason";
    }
  };

=head1 DESCRIPTION

This module provides non-blocking AnyEvent compatible wrapper for Net::Whois::Raw.
It is not trivial to make non-blocking module from blocking one without full rewrite.
This wrapper makes such attempt. To decide how ugly or beautiful this attempt implemented
see source code of the module.

=head1 IMPORT

whois() and get_whois() by default

=head1 Net::Whois::Raw compatibilities and incompatibilities

=over

=item All global $Net::Whois::Raw::* options could be specified to change the behavior

=item User defined functions such as *Net::Whois::Raw::whois_query_sockparams and others
will not affect anything

=item In contrast with Net::Whois::Raw whois and get_whois from this module will never die.
On error first parameter of the callback will be false and second will contain error reason

=back

=head1 FUNCTIONS

=head2 whois DOMAIN [, SRV [, WHICH_WHOIS] [, %PARAMS]], CB

DOMAIN, SRV and WHICH_WHOIS are same as whois arguments from Net::Whois::Raw.

Available %PARAMS are:

=over

=item timeout => $seconds

Timeout for whois request in seconds

=item on_prepare => $cb

Same as prepare callback from AnyEvent::Socket. So you can bind socket to some ip:

  whois 'google.com', on_prepare => sub {
    bind $_[0], AnyEvent::Socket::pack_sockaddr(0, AnyEvent::Socket::parse_ipv4($ip))); 
  }, sub {
    my $info = shift;
  }

=back

CB is a callback which will be called when request will be finished. On success callback arguments
are whois text data and whois server used for request. On failed false value (not undef) and failed reason.

=head2 get_whois DOMAIN [, SRV [, WHICH_WHOIS] [, %PARAMS]], CB

Same explanation.

=head1 NOTICE

=over

=item This module uses AnyEvent::HTTP for http queries, so you should tune $AnyEvent::HTTP::MAX_PER_HOST
to proper value yourself.

=item You should not load Net::Whois::Raw in your code if you are using this module, because this will
cause incorrect work of the module.

=back

=head1 SEE ALSO

L<Net::Whois::Raw>, L<AnyEvent::HTTP>, L<AnyEvent::Socket>

=head1 AUTHOR

Oleg G, E<lt>oleg@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Oleg G

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut
