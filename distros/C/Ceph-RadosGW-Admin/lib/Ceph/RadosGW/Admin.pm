package Ceph::RadosGW::Admin;
$Ceph::RadosGW::Admin::VERSION = '0.4';
use strict;
use warnings;

use LWP::UserAgent;
use Ceph::RadosGW::Admin::HTTPRequest;
use JSON;
use Moose;
use URI;
use URI::QueryParam;
use Ceph::RadosGW::Admin::User;
use namespace::autoclean;

=head1 NAME

Ceph::RadosGW::Admin - Bindings for the rados gateway admin api.

=head1 VERSION

version 0.4

=head1 SYNOPSIS
	
	my $admin = Ceph::RadosGW::Admin->new(
		access_key => 'not really secret',
		secret_key => 'actually secret',
		url        => 'https://your.rados.gateway.com/',
	);
	
	my $user  = $admin->create_user(
		uid          => 'myusername',
		display_name => 'my user name',
	);
	
	# they're really evil, suspending them should be enough
	$user->suspended(1);
	$user->save;
	
	# nah, they're really evil
	$user->delete;
	
	my $otheruser = $admin->get_user(uid => 'other');
	
	my @keys          = $otheruser->keys();
	my @keys_plus_one = $otheruser->create_key();
	
	$otheruser->delete_key(access_key => $keys[0]->{access_key});
	
	my @buckets = $otheruser->get_bucket_info();
	

=head1 DESCRIPTION

This module provides an interface to the
L<Admin OPs|http://docs.ceph.com/docs/master/radosgw/adminops/> interface of a
ceph rados gateway.  It is at this time incomplete, with only the parts needed
by the authors implemented. Patches for the rest of the functionality are
encouraged.

=cut

has secret_key => ( is => 'ro', required => 1 );
has access_key => ( is => 'ro', required => 1 );
has url        => ( is => 'ro', required => 1 );
has useragent => (
	is      => 'ro',
	builder => 'build_useragent',
);

__PACKAGE__->meta->make_immutable;

=head1 METHODS

=head2 get_user

Returns a L<Ceph::RadosGW::Admin::User> object representing the given C<uid>.

Dies if the user does not exist.

Example:

	my $user = $admin->get_user(uid => 'someuserhere');
	
=cut

sub get_user {
	my ($self, %args) = @_;
	
	my %user_data = $self->_request(GET => 'user', %args);
	
	return Ceph::RadosGW::Admin::User->new(
		%user_data,
		_client => $self
	);
}

=head2 create_user

Makes a new user on the rados gateway, and returns a
L<Ceph::RadosGW::Admin::User> object representing that user.

Dies on failure.

Example:

	my $new_user = $admin->create_user(
		uid          => 'username',
		display_name => 'Our New User',
	);

=cut

sub create_user {
	my ($self, %args) = @_;
	
	my %user_data = $self->_request(PUT => 'user', %args);
	
	return Ceph::RadosGW::Admin::User->new(
		%user_data,
		_client => $self
	);
}

sub build_useragent {
	require LWP::UserAgent;
	return LWP::UserAgent->new;
}

sub _debug {
	if ($ENV{DEBUG_CEPH_CALLS}) {
		require Data::Dumper;
		warn Data::Dumper::Dumper(@_);
	}
}

sub _request {
	my ($self, $method, $path, %args) = @_;
	
	my $content = '';

	my $query_string = _make_query(%args, format => 'json');
	
	my $request_builder = Ceph::RadosGW::Admin::HTTPRequest->new(
		method     => $method,
		path       => "admin/$path?$query_string",
		content    => '',
		url        => $self->url,
		access_key => $self->access_key,
		secret_key => $self->secret_key,
	);	

	my $req = $request_builder->http_request();
	
	my $res = $self->useragent->request($req);
	
	_debug($res);
	
	unless ($res->is_success) {
		die sprintf("%s - %s (%s)", $res->status_line, $res->content, $req->as_string);
	}
    
	if ($res->content) {
		my $data = eval {
			JSON::decode_json($res->content);
		};
	
		if (my $e = $@) {
			die "Could not deserialize server response: $e\nContent: " . $res->content . "\n";			
		}
		
		if (ref($data) eq 'HASH') {
			return %$data;
		}
		elsif (ref($data) eq 'ARRAY') {
			return @$data;
		}
		else {
			die "Didn't get an array or hash reference\n";
		}
	} else {
		return;
	}
}

sub _make_query {
	my %args = @_;
	
	my %fixed;
	while (my ($key, $val) = each %args) {
		$key =~ s/_/-/g;
		$fixed{$key} = $val;
	}
	
	my $u = URI->new("", "http");
	
	foreach my $key (sort keys %fixed) {
		$u->query_param($key, $fixed{$key});
	}
	
	
	return $u->query;

}


=head1 TODO

=over 2

=item *

The docs are pretty middling at the moment.

=item *

This module has only been tested against the Dumpling release of ceph.  

=back

=head1 AUTHORS

    Chris Reinhardt
    crein@cpan.org

    Mark Ng
    cpan@markng.co.uk   
    
=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1), L<Admin OPs API|http://docs.ceph.com/docs/master/radosgw/adminops/>
L<Ceph|http://www.ceph.com/>

=cut


1;
__END__
