package AnyEvent::CacheDNS;

use strict;
use warnings;
use base 'AnyEvent::DNS';

use Data::Dumper;

our $VERSION = '0.08';

# Detect AnyEvent >= 6.0.1
my $IS_AE_6X = version->can("parse")
	? version->parse(AnyEvent->VERSION()) >= version->parse('v6.0.1')
	: AnyEvent->VERSION !~ /^ (?: [0-5]\. | 6\.0(?:\.0)? $ )/x;

# Default TTL for AnyEvent < 6.0.1
my $DEFAULT_TTL = undef;

sub import {
	my $package = shift;
	my @options = @_;

	while (@options) {
		my $key = shift @options;
		if ($key eq ':register') {
			$package->register();
		}
	}
}


sub resolve {
	my $cb = pop @_;
	my ($self, $qname, $qtype, %opt) = @_;

	# If we have the value cached then we serve it from there
	my $cache = $self->{_cache}{$qtype} ||= {};
	if (exists $cache->{$qname}) {
		my $response = $cache->{$qname};
		$cb->($response ? ($response) : ());
		return;
	}

	# Perform a request and cache the value
	$self->SUPER::resolve(
		$qname,
		$qtype,
		%opt,
		sub{
			# Note that it could be possible that multiple DNS request are done
			# for a new qname. For instance if an application is doing multiple
			# concurrent HTTP request to the same host then there will be at
			# least one DNS request per HTTP request. That's why we only cache
			# the results of the first DNS request that's successful.
			$cache->{$qname} ||= @_ ? $_[0] : undef;

			# Respect TTL and be backwards compatible with AnyEvent < 6.x
			my $ttl = defined $DEFAULT_TTL
				? $DEFAULT_TTL
				: ($IS_AE_6X && @_ ? int($_[0]->[3] || 0) : 0)
			;

			if ($ttl > 0) {
				# Create expire timer
				my $wt;
				$wt  = AE::timer($ttl, 0, sub {
					$wt = undef;
					delete($cache->{$qname});
				});
			}

			$cb->(@_);
		}
	);
}


sub register {
	my $class = shift;

	my @args = (
		untaint => 1,
	);

	my $key = 'PERL_ANYEVENT_MAX_OUTSTANDING_DNS';
	push @args, max_outstanding => $ENV{$key} * 1 || 1 if exists $ENV{$key};

	my $resolver = $class->new(@args);

	if (exists $ENV{PERL_ANYEVENT_RESOLV_CONF}) {
		my $conf = $ENV{PERL_ANYEVENT_RESOLV_CONF};
		$resolver->_parse_resolv_conf_file($conf) if length $conf;
	}
	else {
		$resolver->os_config();
	}

	$DEFAULT_TTL = abs(int($ENV{PERL_ANYEVENT_DNS_TTL} || 0)) if exists $ENV{PERL_ANYEVENT_DNS_TTL};

	$AnyEvent::DNS::RESOLVER = $resolver;
}


1;

=head1 NAME

AnyEvent::CacheDNS - Simple DNS resolver with caching

=head1 SYNOPSIS

	use AnyEvent;
	use AnyEvent::HTTP;
	
	# Register our DNS resolver as the default resolver
	use AnyEvent::CacheDNS ':register';
	
	# Use AnyEvent as ususal
	my $cond = AnyEvent->condvar;
	http_get "http://search.cpan.org/", sub { $cond->send(); };
	$cond->recv();

=head1 DESCRIPTION

This module provides a very simple DNS resolver that caches its results and can
improve the connection times to remote hosts.

=head1 Import

It's possible to register the this class as AnyEvent's main DNS resolver by
passing the tag C<:register> in the C<use> statement.

=head1 METHODS

=head2 register

Registers a new DNS cache instance as AnyEvent's global DNS resolver.

=head2  ENVIRONMENT

=over

=item C<PERL_ANYEVENT_DNS_TTL>

The effect of setting this variable differs depending on L<AnyEvent> version.

=over

=item AnyEvent 5.x

Default DNS response record cache TTL for older AnyEvent versions.
L<AnyEvent::DNS> <= 6.x doesn't report record TTL and records get
cached for infinite amount of time, therefore running programs won't
detect if cached DNS records have changed.

B<NOTE>: Setting this variable to C<0> disables purging records from
cache.

=item AnyEvent 6.x

Newer versions of AnyEvent report DNS record TTL so records will be
purged from the cache after B<their> TTL expires. Setting this variable to any
positive integer B<OVERRIDES> the TTL for all records to the specified
value, setting variable to C<0> disables purging records from the cache.

=back

=back

=head1 AUTHOR

Emmanuel Rodriguez <potyl@cpan.org>

=head1 COPYRIGHT

(C) 2011 Emmanuel Rodriguez - All Rights Reserved.

=cut
