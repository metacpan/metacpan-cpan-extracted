package Class::DataStore;

=pod

=head1 NAME

Class::DataStore - Generic OO data storage/retrieval

=head1 SYNOPSIS

  my %values = ( one => 1, two => 2 );
  my $store = Class::DataStore->new( \%values );

  # using get/set methods
  $store->set( 'three', 3 );
  my $three = $store->get( 'three' );
  
  # using AUTOLOAD method
  $store->four( 4 );
  my $four = $store->four;
  my @four = $store->four; # returns a list

  my $exists = $store->exists( 'three' ); # $exists = 1
  my $data_hashref = $store->dump;
  $store->clear;

=head1 DESCRIPTION

Class::DataStore implements a simple storage system for object data.  This data
can be accessed via get/set methods and AUTOLOAD. AUTOLOAD calls are not added
to the symbol table, so using get/set will be faster. Using AUTOLOAD also means
that you will not be able to store data with a key that is already used by a
instance method, such as "get" or "exists".

This module was written originally as part of a website framework that was used
for the Democratic National Committee website in 2004.  Some of the
implementations here, such as get() optionally returning a list if called in
array context, reflect the way this module was originally used for building web
applications.

Class::DataStore is most useful when subclassed. To preserve the AUTOLOAD
functionality, be sure to add the following when setting up the subclass:

  use base 'Class::DataStore';
  *AUTOLOAD = \&Class::DataStore::AUTOLOAD;

This module is also a useful add-on for modules that need quick and simple data
storage, e.g. to store configuration data:

  $self->{_config} = Class::Datastore->new( $config_data );
  sub config { return $_[0]->{_config}; }
  my $server = $self->config->server;
  my $sender = $self->config->get( 'sender' );

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

our $AUTOLOAD;
our $VERSION = '0.07';

=pod

=head2 new( $data_hashref )

The $data_hashref is stored in $self->{_data}. Returns the blessed object.

=cut

sub new {
	my $class = shift;
	my $data = shift || {};

	my $self = bless { _data => $data }, $class;
	return $self;
}

=pod

=head2 exists( $key )

Returns 1 if the $key exists in the $self->{_data} hashref.  Otherwise, returns
0.

=cut

sub exists {
	my $self = shift;
	my $key = shift;
	
	return 1 if exists $self->{_data}->{$key};
	return 0;
}

=pod

=head2 get( $key )

Returns the value of $self->{_data}->{$key}, or undef.

If the value is stored as an ARRAYREF, HASHREF or a scalar, and wantarray is
true, the return value will be a list. Otherwise, the value will be returned
unaltered.

=cut

sub get {
	my $self = shift;
	my $key = shift;
	
	my $value = $self->{_data}->{$key};
	
	if ( ref $value eq 'ARRAY' ) {
		return wantarray ? @$value : $value;
	} elsif ( ref $value eq 'HASH' ) {
		return wantarray ? %$value : $value;
	} elsif ( ref $value eq '' ) {
		return wantarray ? ( $value ) : $value;
	} else {
		return $value;
	}
}

=pod

=head2 set( $key => $value )

Sets $self->{_data}->{$key} to $value, and returns $value.  Values must be
scalars, including, of course, references.

=cut

sub set {
	my $self = shift;
	my $key = shift;
	my $value = shift;

	$self->{_data}->{$key} = $value;
	return $value;
}


=pod

=head2 dump()

Returns the $self->{_data} as hashref or hash, depending on the call.

=cut

sub dump {
	my $self = shift;
	
	return wantarray ? %{ $self->{_data} } : $self->{_data};
}


=pod

=head2 clear()

Deletes all the keys from $self->{_data}. Returns the number of keys deleted.

=cut

sub clear {
	my $self = shift;
	my $ct = 0;
	
	foreach my $key ( keys %{ $self->{_data} } ) {
		delete $self->{_data}->{$key};
		$ct++;
	}
	return $ct;
}


=pod

=head2 AUTOLOAD()

Tries to determine $key from the method call. Returns $self->{_data}->{$key},
or undef.

=cut

sub AUTOLOAD {
	no strict;
	if ( $AUTOLOAD =~ /(\w+)$/ ) {
		my $key = $1;
		my ( $self, $value ) = @_;
		if ( @_ == 2 ) {
			return $self->set( $key, $value );
		} else {
			return $self->get( $key );
		}
	} else {
		return;
	}
}

sub DESTROY {}
												  
=pod

=head1 AUTHOR

Eric Folley, E<lt>eric@folley.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Eric Folley

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut

1;
