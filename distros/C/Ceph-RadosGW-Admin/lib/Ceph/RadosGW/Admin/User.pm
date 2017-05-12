package Ceph::RadosGW::Admin::User;
$Ceph::RadosGW::Admin::User::VERSION = '0.4';
use strict;
use warnings;

use Moose;
use namespace::autoclean;

=head1 NAME

Ceph::RadosGW::Admin::User - A Rados Gateway User

=head1 VERSION

version 0.4

=head1 DESCRIPTION

This class provides objects that represent users on a rados gateway object
store.

=cut

has user_id      => (is => 'ro', required => 1, isa => 'Str');
has display_name => (is => 'rw', required => 1, isa => 'Str');
has suspended    => (is => 'rw', required => 1, isa => 'Bool');
has max_buckets  => (is => 'rw', required => 1, isa => 'Int');
has subusers     => (is => 'rw', required => 1, isa => 'ArrayRef[Ceph::RadosGW::Admin::User]');
has keys         => (is => 'rw', required => 1, isa => 'ArrayRef[HashRef[Str]]');
has swift_keys   => (is => 'rw', required => 1, isa => 'ArrayRef[Str]');
has caps         => (is => 'rw', required => 1, isa => 'ArrayRef[Str]');
has _client      => (is => 'ro', required => 1, isa => 'Ceph::RadosGW::Admin');

__PACKAGE__->meta->make_immutable;

=head1 METHODS

=head2 delete

Removes the user from the rados system.

Dies on failure.

=cut

sub delete {
	my ($self, %args) = @_;
	
	$self->_request(DELETE => 'user', %args);
	
	return 1;
}

=head2 save

Save changes to the user.

Dies on failure.

=cut

sub save {
	my ($self) = @_;
	
	return $self->_request(
		POST         => 'user',
		display_name => $self->display_name,
		suspended    => $self->suspended,
		max_buckets  => $self->max_buckets,
	);
}

=head2 create_key

Create an access/secret key pair. Returns the keys as a list of hashrefs.

Dies on failure.

=cut

sub create_key {
	my ($self) = @_;
	
	return $self->_request(
		PUT          => 'user',
		key          => '',
		generate_key => 'True',
	);
}

=head2 delete_key

Delete a specific access/secret key pair.

Dies on failure.

=cut

sub delete_key {
	my ($self, %args) = @_;
	
	return $self->_request(
		DELETE     => 'user',
		key        => '',
		access_key => $args{'access_key'},
	);
}

=head2 get_usage

Get usage information for the user.

Dies on failure.

=cut

sub get_usage {
	my ($self, %args) = @_;

	my %usage = $self->_request(GET => 'usage', %args);

	return %usage;
}

=head2 get_bucket_info

Gets bucket information and statistics for the user.

Dies on failure.

=cut

sub get_bucket_info {
	my ($self) = @_;

	my @info = $self->_request(
		GET   => 'bucket',
		stats => 'True',    
	);

	return @info;
}

sub _request {
	my ($self, @args) = @_;
	
	return $self->_client->_request(
		@args,
		uid => $self->user_id,
	);
}

sub as_hashref {
	my ($self) = @_;
	
	return {
		map { $_ => $self->$_ } qw/user_id display_name suspended max_buckets keys caps/
	};
}

1;
