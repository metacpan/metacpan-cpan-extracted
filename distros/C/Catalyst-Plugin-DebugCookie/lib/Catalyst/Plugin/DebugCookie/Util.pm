package Catalyst::Plugin::DebugCookie::Util; 

use strict;
use warnings;
use MRO::Compat;
use Digest::MD5 qw(md5_hex);
use Sub::Exporter
    -setup => { exports => [ qw(make_debug_cookie check_debug_cookie_value) ] };

=head1 NAME

Catalyst::Plugin::DebugCookie::Util - Utility class to handle abstracting the cookie get/set 

=head1 DESCRIPTION

These methods provide an interface for creating the debug cookie, and also checking it later
for when a page is hit with the 'is_debug' query parameter

=cut

=head2 make_debug_cookie($c, $username) 

Creates a debug cookie with a hash of your secret key and username 

=cut
sub make_debug_cookie {
	my ($c, $username) = @_;

	my $config = $c->config->{'Plugin::DebugCookie'} || {};
	my $secret_key = $config->{secret_key};
	die "config must define 'secret_key'" unless grep {defined && length} $secret_key;
	my $cookie_name = (defined $config->{cookie_name})?$config->{cookie_name}:'debug_cookie';

	$c->res->cookies->{$cookie_name} = {
		value => md5_hex($username, $secret_key)
	};

	return 1;
}


=head2 check_debug_cookie_value($c, $username) 

Checks the debug cookie and verifies the value matches
the hash of your secret key and username 

=cut
sub check_debug_cookie_value {
	my ($c, $username) = @_;

	my $config = $c->config->{'Plugin::DebugCookie'} || {};
	my $secret_key = $config->{secret_key};
	die "config must define 'secret_key'" unless grep {defined && length} $secret_key;
	my $cookie_name = (defined $config->{cookie_name})?$config->{cookie_name}:'debug_cookie';

	if (exists ( $c->request->cookies->{$cookie_name}) ) {
		my $cookie_val = $c->request->cookies->{$cookie_name}->value;
		if (md5_hex($username, $secret_key) eq $cookie_val) {
			return 1;
		}
	}
	return 0;
}

=head1 AUTHOR

 John Goulah       <jgoulah@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
