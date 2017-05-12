package DNS::ZoneEdit;

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use CGI::Util qw(escape);

use base qw(LWP::UserAgent);

use constant URL => 'dynamic.zoneedit.com/auth/dynamic.html';

our $VERSION = 1.1;

=head1 NAME

DNS::ZoneEdit - Update your ZoneEdit dynamic DNS entries

=head1 SYNOPSIS

This module allows you to update your ZoneEdit ( http://www.zoneedit.com/ )
dynamic DNS records. This is done via an http get using the C<LWP::UserAgent>
module.

	use DNS::ZoneEdit;

	my $ze = DNS::ZoneEdit->new();
	$ze->update( hostname => "cpan.org", username => "foo", password => "bar" ) || die "Failed: $@";

=head1 METHODS

=over 4

=cut

=item DNS::ZoneEdit->new();

Create a new ZoneEdit object. This is actually an inheritted L<LWP::UserAgent>
object so you can use any of the methods defined in that class. For example,
if you are behind a proxy server:

	my $ze = DNS::ZoneEdit->new();
	$ze->proxy('http', 'http://proxy.sn.no:8001/');

=cut

sub new {
	my ($pack,@args) = @_;
	my $obj = $pack->SUPER::new(@args);
	$obj->agent("DNS::ZoneEdit perl module");
	return $obj;
}


sub _can_do_https {
	eval "use Crypt::SSLeay";

	return ($@ eq "");
}


sub _make_request_url {
	my ($self,%args) = @_;

	my %get;
	while (my ($k,$v) = each %args) {
		if    ( $k eq "username" ) { $self->{"username"} = $v }
		elsif ( $k eq "password" ) { $self->{"password"} = $v }
		elsif ( $k eq "hostname" ) { $get{host} = $v         }
		elsif ( $k eq "myip"     ) { $get{dnsto} = $v        }
		elsif ( $k eq "tld"      ) { $get{zones} = $v        }
		elsif ( $k eq "secure"   ) { $self->{"secure"} = $v   }
		else { carp "update(): Bad argument $k" }
	}

	if (defined $self->{secure}) {
		if ($self->{secure} && ! _can_do_https()) {
			croak "Can't run in secure mode - try installing Crypt::SSLeay";
		}
	} else {
	    $self->{secure} = _can_do_https();
    }

	if ( !$self->{secure} ) {
		carp "** USING INSECURE MODE - PLEASE READ THE DOCUMENTATION **\n";
	}

	## Make the GET request URL.
	my $proto = $self->{"secure"} ? "https://" : "http://";
	my $query = join('&', map { escape($_)."=".escape($get{$_}) } keys %get);
	return $proto . URL() . "?" . $query;
}

=item update(%args);

Updates your ZoneEdit dynamic DNS records. Valid C<%args> are:

=over 8

C<username> - Your ZoneEdit login name. This is required.

C<password> - The corresponding password. This is required.

C<hostname> - The FQDN of host being updated. This is required.

Contains a comma-delimited list of hosts that have IP addresses. This parameter
may be C<*.domain.com> to update a wildcard A-record.

C<myip> - The IP address of the client to be updated.  This
defaults to the IP address of the incoming connection (handy if you are
being natted).

C<tld> - The root domain of your hostname, for example if your hostname is
C<example.co.uk> you can set C<tld> to C<co.uk>.  This is to support an
undocumented "feature" of zoneedit where you sometimes need to specify it to
to update your zone.

C<secure> - Values are either C<1> or C<0>. If C<1>, then SSL https is used to
connect to ZoneEdit. The SSL connection has the big advantage that your 
passwords are not passed in plain-text accross the internet. Secure is on by
default if Crypt::SSLeay is installed. A warning will be generated if it's not
installed unless you set C<secure> to C<0>. If you set C<secure>  to C<1> and the
module is unavailable, the module will C<croak>.

=back

Returns C<TRUE> on success. On failure it returns C<FALSE> and 
sets C<$@>.

=cut

sub update {
	my ($self,%args) = @_;

	croak "update(): Argument 'username' is required" 
		unless defined $args{"username"};

	croak "update(): Argument 'password' is required" 
		unless defined $args{"password"};

	croak "update(): Argument 'hostname' is required" 
		unless defined $args{"hostname"};

	my $update = $self->_make_request_url(%args);

	my $resp = $self->get($update);
	if ($resp->is_success) {
		chomp(my $content = $resp->content);
		if ( $content =~ m/CODE="2\d+"/ ) {
			return 1;
		} else {
			$@ = 'Request failed: "'.$content.'"';
			return;
		}
	} else {
		$@ = 'HTTP Request failed: "'.$resp->status_line.'"';
		return;
	}
}

=item get_basic_credentials();

Since a ZoneEdit object is an subclass of C<LWP::UserAgent>, it overrides
this UserAgent method for your convenience. It uses the credentials passed
in the update method. There is no real reason to call, or override this method.

=cut

sub get_basic_credentials { ($_[0]->{"username"}, $_[0]->{"password"}) }

=back

=head1 NOTES

There are some example scripts in the C<examples> directory of the module
distribution. These are designed to run out of cron (or similar). You should
not run them too often to avoid overloading the ZoneEdit servers. Ideally
your code should cache the existing value for your IP, and only update
ZoneEdit when it changes.

=head1 ACKNOWLEDGEMENTS

This module is based on Gavin Brock's excellent L<DNS::EasyDNS>.

For more information about the ZoneEdit services please visit 
http://www.zoneedit.com/. This module is not written nor supported by 
ZoneEdit LLC.

=head1 COPYRIGHT

Copyright (c) 2003-2006 Gavin Brock gbrock@cpan.org,
Copyright 2009-2010 Evan Giles.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<LWP::UserAgent>, L<DNS::EasyDNS>

=cut

1; # End of DNS::ZoneEdit
