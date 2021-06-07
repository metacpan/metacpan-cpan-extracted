package CGI::ACL;

# Author Nigel Horne: njh@bandsman.co.uk
# Copyright (C) 2018, Nigel Horne

# Usage is subject to licence terms.
# The licence terms of this software are as follows:
# Personal single user, single computer use: GPL2
# All other users (including Commercial, Charity, Educational, Government)
#	must apply in writing for a licence for use from Nigel Horne at the
#	above e-mail.

# TODO:  Add deny_all_countries() and allow_country() methods, so that we can easily block all but a few countries.

use 5.006_001;
use warnings;
use strict;
use namespace::clean;
use Carp;
use Net::CIDR;

=head1 NAME

CGI::ACL - Decide whether to allow a client to run this script

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Does what it says on the tin.

    use CGI::Lingua;
    use CGI::ACL;

    my $acl = CGI::ACL->new();
    # ...
    my $denied = $acl->all_denied(info => CGI::Lingua->new(supported => 'en'));

=head1 SUBROUTINES/METHODS

=head2 new

Creates a CGI::ACL object.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	return bless { }, $class;
}

=head2 allow_ip

Give an IP (or CIDR) that we allow to connect to us

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
		$self->{_allowed_ips}->{$params{'ip'}} = 1;
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
		Carp::carp('Usage: deny_country($ip_address)');
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
				$self->{_deny_countries}->{lc($country)} = 1;
			}
		} else {
			$self->{_deny_countries}->{lc($c)} = 1;
		}
	} else {
		Carp::carp('Usage: deny_country($ip_address)');
	}
	return $self;
}

=head2 allow_country

Give a country, or a reference to a list of countries, that we will allow to access us

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
				$self->{_allow_countries}->{lc($country)} = 1;
			}
		} else {
			$self->{_allow_countries}->{lc($c)} = 1;
		}
	} else {
		Carp::carp('Usage: allow_country($country)');
	}
	return $self;
}

=head2 all_denied

If any of the restrictions return false then return false, which should allow access.
Note that by default localhost isn't allowed access, call allow_ip('127.0.0.1') to enable it.

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

	if((!defined($self->{_allowed_ips})) && !defined($self->{_deny_countries})) {
		return 0;
	}

	my $addr = $ENV{'REMOTE_ADDR'} ? $ENV{'REMOTE_ADDR'} : '127.0.0.1';

	if($self->{_allowed_ips}) {
		if($self->{_allowed_ips}->{$addr}) {
			return 0;
		}

		my @cidrlist;
		foreach my $block(keys(%{$self->{_allowed_ips}})) {
			@cidrlist = Net::CIDR::cidradd($block, @cidrlist);
		}
		if(Net::CIDR::cidrlookup($addr, @cidrlist)) {
			return 0;
		}
	}

	if($self->{_deny_countries} || $self->{_allow_countries}) {
		my %params;

		if(ref($_[0]) eq 'HASH') {
			%params = %{$_[0]};
		} elsif(@_ % 2 == 0) {
			%params = @_;
		} else {
			$params{'lingua'} = shift;
		}

		if(my $lingua = $params{'lingua'}) {
			if($self->{_deny_countries}->{'*'} && !defined($self->{_allow_countries})) {
				return 0;
			}
			if(my $country = $lingua->country()) {
				if($self->{_deny_countries}->{'*'}) {
					# Default deny
					return !$self->{_allow_countries}->{$country};
				}
				# Default allow
				return $self->{_deny_countries}->{$country};
			}
			# Unknown country - disallow access
		} else {
			Carp::carp('Usage: all_denied($lingua)');
		}
	}

	return 1;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-acl at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-ACL>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

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

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-ACL>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=CGI::ACL>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2021 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
