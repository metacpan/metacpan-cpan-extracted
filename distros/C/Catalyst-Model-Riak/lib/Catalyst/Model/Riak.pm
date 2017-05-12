package Catalyst::Model::Riak;
BEGIN {
	$Catalyst::Model::Riak::AUTHORITY = 'cpan:NLTBO';
}
BEGIN {
	$Catalyst::Model::Riak::VERSION = '0.07';
}

use Net::Riak;
use Moose;

BEGIN { extends 'Catalyst::Model' }

has host	=> ( 
	isa => 'Str', 
	is => 'ro', 
	required => 1, 
	default => sub { 'http://localhost:8098' } 
);

has ua_timeout	=> ( 
	isa => 'Int', 
	is => 'ro', 
	required => 1, 
	default => 900 
);

has dw		=> ( 
	isa => 'Int', 
	is => 'rw', 
	default => 1, 
	trigger => \&_dw_set 
);

has w		=> ( 
	isa => 'Int', 
	is => 'rw', 
	default => 1, 
	trigger => \&_w_set 
);

has r		=> ( 
	isa => 'Int', 
	is => 'rw', 
	default => 1, 
	trigger => \&_r_set 
);

has container	=> ( 
	isa => 'Net::Riak::Bucket', 
	is => 'rw' 
);

has 'client' => (
	isa => 'Net::Riak',
	is  => 'rw',
	lazy_build => 1,
);

has 'object' => (
	isa => 'Net::Riak::Object|Undef',
	is  => 'rw'
);

sub _build_client {
	my($self) = @_;

	my $conn = Net::Riak->new(
		host => $self->host,
		ua_timeout => $self->ua_timeout,
	);
	if ( $self->dw != $conn->client->dw ) { $conn->client->dw($self->dw); }
	if ( $self->w != $conn->client->w ) { $conn->client->w($self->w); }
	if ( $self->r != $conn->client->r ) { $conn->client->r($self->r); }

	return $conn;
}

sub bucket {
	my($self, $data) = @_;

	if ( defined($data) ) {
		$self->container($self->client->bucket($data));
	}

	return $self->container;
}

sub buckets {
	my($self) = @_;

	return $self->client->all_buckets;
}

sub create {
	my($self, $data) = @_;


	if ( defined($data->{key}) && defined($data->{value}) ) 
	{
		my $object = $self->bucket->new_object($data->{key}, $data->{value});
		return $object->store;
	}
}

sub delete {
	my($self, $data) = @_;

	if ( defined($data->{key}) ) {
		my $object = $self->get($data);

		if ( defined($object) ) {
			return $object->delete;
		}
	}
}

sub get {
	my($self, $data) = @_;
	
	if ( defined($data->{key}) ) {
		my $object = $self->bucket->get($data->{key});
		if ( $object->exists ) {
			$self->object( $object );
		} 
	}

	return $self->object;
}

sub read {
	my($self, $data) = @_;
	return $self->get($data);
}

sub update {
	my($self, $data) = @_;
	
	if ( defined($data->{key}) ) {
		my $object = $self->get({ key => $data->{key} });

		if ( defined($object) ) {
			$object->data($data->{value});
			return $object->store($self->w, $self->dw);
		}
	}
}

sub links {
	my($self, $data) = @_;
	if ( defined($data) && defined($data->{key}) )
	{
		my $object = $self->get($data->{key});
		if ( defined($object) )
		{
			return $object->links();
		}
	}
}

sub _dw_set
{
	my($self, $nr) = @_;
	return $self->client->client->dw($nr);
}

sub _w_set
{
	my($self, $nr) = @_;
	return $self->client->client->w($nr);
}

sub _r_set
{
	my($self, $nr) = @_;
	return $self->client->client->r($nr);
}

1;

__END__
=pod

=head1 NAME

Catalyst::Model::Riak - Basho/Riak model class for Catalyst

=head1 VERSION

version 0.01

=head1 SYNOPSYS

	# Use this to create a new model
	script/myapp_create.pl model ModelName Riak http:/192.168.0.1:8089 900
	
	
	# In you controller use
	my $coder = JSON::XS->new->utf8->pretty->allow_nonref;
	
	#
	# Set bucket
	#
	$c->model("ModelName")->bucket('Bucket');
	
	#
	# Create a key/value pair in the bucket
	$c->model('ModelName')->create( { key => 'key', value => $coder->encode($data) } );
	
	#
	# Read key/value pair from the 'Bucket'
	my $object = $c->model('ModelName')->get({ key => 'key' });
	
	#
	# Update a key/value pair in the bucket
	$c->model('ModelName')->update( { key => 'key', value => $code->encode($newdata) } );
	
	#
	# Delete a key/value pair from the bucket
	$c->model('ModelName')->delete( { key => 'key' } );

	#
	# Get linked objects
	$c->model('ModelName')->links( { key => 'key' } );

	#
	# Or
	#
	
	#
	# Create a key/value pair
	my $object = $c->model("ModelName")->bucket('Container')->new_object('key', $coder->encode($data) );
	$object->store;
	
	#
	# Get a key/value pair
	my $object = $c->model("ModelName")->bucket('Container')->get('key');
	
	#
	# Update a key/value pair
	$object->data($coder->encode($newdata));
	
	#
	# Delete a key/value pair
	$object->delete;

	
=head1 DESCRIPTION
	
Use this model set create a new L<Catalyst::Model::Riak> model for your Catalyst application.
Check the L<Net::Riak> documentation for addtional information. Also visit L<http://www.basho.com> 
for more information on Riak.

=head1 METHODS

=head2 bucket

Set the bucket and returns a Net::Riak::Bucket object.

	$c->model("ModelName")->bucket("Container");

=head2 buckets

Returns an array of all available buckets.

=head2 create

Creates a new key/value pair

	$c->model("ModelName")->create({ key => 'keyname', value => $json_data });
	

=head2 delete

Deletes a key/value pair

=head2 get

Get a key/value pair from the riak server. It returns a L<Net::Riak::Object>.

=head2 read

Synonym for get

=head2 update

Update a key/value pair

	$c->model('ModelName')->update( { key => 'key', value => $json_data } );

=head2 dw

Get or set the number of partitions to wait for write confirmation

=head2 w

Get or set the number of responding partitions to wait for while writing or updating a value

=head2 r

Get or set the number of responding partitions to wait for while retrieving an object

=head1 SUPPORT

Repository

  https://github.com/Mainframe2008/CatRiak
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/Mainframe2008/CatRiak/issues

=head1 AUTHOR

Theo Bot <nltbo@cpan.org> L<http://www.proxy.nl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Theo Bot

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself

=cut