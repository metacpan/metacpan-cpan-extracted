package CGI::ACL;

# Author Nigel Horne: njh@bandsman.co.uk
# Copyright (C) 2017-2026, Nigel Horne

# Usage is subject to licence terms.
# The licence terms of this software are as follows:
# Personal single user, single computer use: GPL2
# All other users (including Commercial, Charity, Educational, Government)
#	must apply in writing for a licence for use from Nigel Horne at the
#	above e-mail.

# TODO:  Add deny_all_countries() method, so that we can easily block all but a few countries.

# TODO: Add a rate limiter to block brute-force attacks
# use Net::CIDR::Lite;
# my $rate_limiter = Net::CIDR::Lite->new;
# $rate_limiter->add("$_/32") for @recent_ips;  # Track IPs in a shared cache

use 5.006_001;
use warnings;
use strict;
use namespace::clean;
use Carp;
use Net::CIDR;
use Regexp::Common qw/net/;
use Scalar::Util;
use Socket;

=head1 NAME

CGI::ACL - Decide whether to allow a client to run this script

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

Does what it says on the tin,
providing control client access to a CGI script based on IP addresses and geographical location (countries).

    use CGI::Lingua;
    use CGI::ACL;

    my $acl = CGI::ACL->new();
    # ...
    my $denied = $acl->all_denied(info => CGI::Lingua->new(supported => 'en'));

The module optionally integrates with L<CGI::Lingua> for detecting the client's country.

=head1 SUBROUTINES/METHODS

=head2 new

Creates an instance of the CGI::ACL class.
Handles both hash and hashref arguments.
Includes basic error handling for invalid arguments.

    my $acl = CGI::ACL->new(allowed_ips => { '127.0.0.1' => 1 });

=cut

sub new
{
	my $class = shift;

	# Handle hash or hashref arguments
	my %args;
	if((@_ == 1) && (ref $_[0] eq 'HASH')) {
		%args = %{$_[0]};
	} elsif((@_ % 2) == 0) {
		%args = @_;
	} else {
		carp(__PACKAGE__, ': Invalid arguments passed to new()');
		return;
	}

	if(!defined($class)) {
		if((scalar keys %args) > 0) {
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}
		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
	}

	return bless { %args }, $class;
}

=head2 allow_ip

Give an IP (or CIDR block) that we allow to connect to us.

    use CGI::ACL;

    # Allow Google to connect to us
    my $acl = CGI::ACL->new()->allow_ip(ip => '8.35.80.39');

=cut

sub allow_ip {
	my $self = shift;
	my %params;

	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::carp('Usage: allow_ip($ip_address)');
	} elsif(@_ % 2 == 0) {
		%params = @_;
	} else {
		$params{'ip'} = shift;
	}

	if(defined($params{'ip'})) {
		$self->{allowed_ips}->{$params{'ip'}} = 1;
	} else {
		Carp::carp('Usage: allow_ip($ip_address)');
	}
	return $self;
}

=head2 deny_country

Give a country, or a reference to a list of countries, that we will not allow to access us

    use CGI::ACL;

    # Don't allow the UK to connect to us
    my $acl = CGI::ACL->new()->deny_country('GB');

    # Don't allow any countries to connect to us (a sort of 'default deny')
    my $acl = CGI::ACL->new()->deny_country('*');

=cut

sub deny_country {
	my $self = shift;
	my %params;

	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::carp('Usage: deny_country($country)');
		return;
	} elsif(@_ % 2 == 0) {
		%params = @_;
	} else {
		$params{'country'} = shift;
	}

	if(defined(my $c = $params{'country'})) {
		# This shenanigans allows country to be a scalar or list
		if(ref($c) eq 'ARRAY') {
			foreach my $country(@{$c}) {
				$self->{deny_countries}->{lc($country)} = 1;
			}
		} else {
			$self->{deny_countries}->{lc($c)} = 1;
		}
	} else {
		Carp::carp('Usage: deny_country($ip_address)');
	}
	return $self;
}

=head2 allow_country

Give a country, or a reference to a list of countries, that we will allow to access us,
overriding the deny list if needed.

    use CGI::ACL;

    # Allow only the UK and US to connect to us
    my @allow_list = ('GB', 'US');
    my $acl = CGI::ACL->new()->deny_country('*')->allow_country(country => \@allow_list);

=cut

sub allow_country {
	my $self = shift;
	my %params;

	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::carp('Usage: allow_country($country)');
	} elsif(@_ % 2 == 0) {
		%params = @_;
	} else {
		$params{'country'} = shift;
	}

	if(defined(my $c = $params{'country'})) {
		# This shenanigans allows country to be a scalar or list
		if(ref($c) eq 'ARRAY') {
			foreach my $country(@{$c}) {
				$self->{allow_countries}->{lc($country)} = 1;
			}
		} else {
			$self->{allow_countries}->{lc($c)} = 1;
		}
	} else {
		Carp::carp('Usage: allow_country($country)');
	}
	return $self;
}

=head2 all_denied

Evaluates all restrictions (IP and country) and determines if access is denied.

If any of the restrictions return false then return false, which should allow access.
Access is allowed by default if no restrictions are set,
however as soon as any restriction is set you may find you need to explicitly allow access.
Note, therefore, that by default localhost isn't allowed access, call allow_ip('127.0.0.1') to enable it.

    use CGI::Lingua;
    use CGI::ACL;

    # Allow Google to connect to us
    my $acl = CGI::ACL->new()->allow_ip(ip => '8.35.80.39');

    if($acl->all_denied()) {
    	print 'You are not allowed to view this site';
	return;
    }

    $acl = CGI::ACL->new()->deny_country(country => 'br');

    if($acl->all_denied(lingua => CGI::Lingua->new(supported => ['en']))) {
    	print 'Brazilians cannot view this site for now';
	return;
    }

=cut

sub all_denied {
	my $self = shift;

	if((!defined($self->{allowed_ips})) && !defined($self->{deny_countries})) {
		return 0;
	}

	my $addr = $ENV{'REMOTE_ADDR'} ? $ENV{'REMOTE_ADDR'} : '127.0.0.1';

	return 1 unless $addr =~ /^$RE{net}{IPv4}$/ || $addr =~ /^$RE{net}{IPv6}$/;

	if ($self->{deny_cloud}) {
		return 1 if _is_cloud_host($addr);
	}

	if($self->{allowed_ips}) {
		if($self->{allowed_ips}->{$addr}) {
			return 0;
		}

		my @cidrlist;
		foreach my $block(keys(%{$self->{allowed_ips}})) {
			@cidrlist = Net::CIDR::cidradd($block, @cidrlist);
		}
		if(Net::CIDR::cidrlookup($addr, @cidrlist)) {
			return 0;
		}
	}

	if($self->{deny_countries} || $self->{allow_countries}) {
		my %params;

		if(ref($_[0]) eq 'HASH') {
			%params = %{$_[0]};
		} elsif(@_ % 2 == 0) {
			%params = @_;
		} else {
			$params{'lingua'} = shift;
		}

		if(my $lingua = $params{'lingua'}) {
			if($self->{deny_countries}->{'*'} && !defined($self->{allow_countries})) {
				return 0;
			}
			if(my $country = $lingua->country()) {
				$country = lc($country);
				if($self->{deny_countries}->{'*'}) {
					# Default deny
					return $self->{allow_countries}->{$country} ? 0 : 1;
				}
				# Default allow
				return $self->{deny_countries}->{$country} ? 1 : 0;
			}
			# Unknown country - disallow access
		} else {
			Carp::carp('Usage: all_denied($lingua)');
		}
	}

	return 1;
}

sub _is_cloud_host {
	my $ip = $_[0];

	my $hostname = verified_rdns($ip) or return 0;

	# AWS
	return 1 if $hostname =~ /\.compute(-\d+)?\.amazonaws\.com$/;
	return 1 if $hostname =~ /\.compute\.amazonaws\.com$/;

	# Google Cloud
	return 1 if $hostname =~ /\.bc\.googleusercontent\.com$/;

	# Azure
	return 1 if $hostname =~ /\.cloudapp\.net$/;
	return 1 if $hostname =~ /\.azure\.com$/;

	# DigitalOcean
	return 1 if $hostname =~ /digitalocean/;

	# Linode
	return 1 if $hostname =~ /\.members\.linode\.com$/;

	# Hetzner
	return 1 if $hostname =~ /hetzner/;
	return 1 if $hostname =~ /your-server\.de$/;

	# OVH
	return 1 if $hostname =~ /\.ovh\.net$/;
	return 1 if $hostname =~ /^ip-\d+-\d+-\d+-\d+\.eu$/;

	return 0;
}

sub _verified_rdns {
	my $ip = $_[0];

	# Convert dotted quad to packed format
	my $packed = inet_aton($ip) or return;

	# Step 1: reverse lookup
	my ($hostname) = gethostbyaddr($packed, AF_INET) or return;

	# Step 2: forward lookup
		my @forward_ips = map { inet_ntoa($_) }
		grep { defined }
		map { inet_aton($_) }
		($hostname);

	# Step 3: confirm match
	return ($hostname && grep { $_ eq $ip } @forward_ips) ? $hostname : undef;
}

=head2 deny_cloud

Enables blocking of requests originating from major cloud-hosting providers
such as Amazon Web Services (AWS), Google Cloud Platform (GCP), Microsoft Azure,
DigitalOcean, Linode, Hetzner, and OVH.

This method relies on verified reverse DNS lookups to classify the client's
network origin.
A reverse DNS lookup is performed on the client's IP address,
and the resulting hostname is then forward-confirmed to ensure that it is not spoofed.
If the hostname matches known patterns associated with cloud infrastructure providers,
access is denied.

This feature is useful for preventing automated bots, scrapers, and abusive
traffic commonly launched from cloud environments, while still allowing access
from residential and business networks.

    use CGI::ACL;

    my $acl = CGI::ACL->new()->deny_cloud();

    if($acl->all_denied()) {
        print "Access from cloud-hosted systems is not permitted.";
        exit;
    }

Returns the object instance to allow method chaining.

=cut

sub deny_cloud {
	my $self = shift;

	$self->{deny_cloud} = 1;
	return $self;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-acl at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-ACL>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

A VPN or proxy would most likely bypass the IP-based access control.

=head1 SEE ALSO

L<CGI::Lingua>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::ACL

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/CGI-ACL>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-ACL>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/CGI-ACL>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=CGI-ACL>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=CGI::ACL>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2026 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
