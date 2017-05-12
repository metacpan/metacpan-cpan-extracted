package Catalyst::Model::Memcached;

use strict;
use warnings;
use 5.0100;

use Moose;

BEGIN { extends 'Catalyst::Model' };
use Cache::Memcached::Fast;

use version; our $VERSION = qv('0.02');

my $primary_key;
my $ttl;

sub BUILD {
	my $self = shift;
	# Fix namespace
	$self->{__ns_chunk} = lc ref $self;
	$self->{__ns_chunk} =~ /.+::([^:]+)$/;
	$self->{__ns_chunk} = $1 . '.';
	$self->{__cache} //= Cache::Memcached::Fast->new( $self->{args} );
	no strict 'refs';
	$self->{primary_key} = ${(ref $self) . "::primary_key"};
	die 'Primary key is a must' unless $self->{primary_key};
	$self->{ttl} = ${(ref $self) . "::ttl"} if ${(ref $self) . "::ttl"};
	return $self;
}

#######################################################################
# Wrapper methods - imitating DBIx schema
sub search {
	my ( $self, $hash ) = @_;
	if ( ref $hash ne 'HASH' || ! $hash->{ $self->{primary_key} } ) {
		die 'Search needs hash ref with primary_key';
	}
	return $self->{__cache}->get( $self->{__ns_chunk} . $hash->{ $self->{primary_key} } );
}

sub find {
	my ( $self, $hash ) = @_;
	if ( ref $hash ne 'HASH' || ! $hash->{ $self->{primary_key} } ) {
		die 'Find needs hash ref with primary_key';
	}
	return $self->{__cache}->get( $self->{__ns_chunk} . $hash->{ $self->{primary_key} } );
}

sub find_or_new {
	my ( $self, $hash ) = @_;
	if ( ref $hash ne 'HASH' || ! $hash->{ $self->{primary_key} } ) {
		die 'Find_or_new needs hash ref with primary_key';
	}
	my $res = $self->find( $hash );
	unless ( $res ) {
		$self->create( $hash );
		$res = $hash;
	}
	return $res;
}

sub create {
	my ( $self, $hash ) = @_;
	if ( ref $hash ne 'HASH' || ! $hash->{ $self->{primary_key} } ) {
		die 'Create needs hash ref';
	}
	$self->{__cache}->set( $self->{__ns_chunk} . $hash->{ $self->{primary_key} }, $hash, $self->{ttl} );
	return $hash;
}

sub delete {
	my ( $self, $hash ) = @_;
	if ( ref $hash ne 'HASH' || ! $hash->{ $self->{primary_key} } ) {
		die 'Delete needs hash ref';
	}
	return $self->{__cache}->delete( $self->{__ns_chunk} . $hash->{ $self->{primary_key} } );

}

#######################################################################
# internals
sub set_primary_key {
	my ( $class, $pk ) = @_;
	$pk = $pk->[0] if ref $pk eq 'ARRAY';
	no strict 'refs';
	${$class."::primary_key"} = $pk;
	return 1;
}
sub set_ttl {
	my ( $class, $pk ) = @_;
	$pk = $pk->[0] if ref $pk eq 'ARRAY';
	no strict 'refs';
	${$class."::ttl"} = $pk;
	return 1;
}

END { }            # module clean-up code

1;

__END__

=pod

=head1 NAME

Catalyst::Model::Memcached - Wrapper for memcached imitating Catalyst models

=head1 SYNOPSIS

  package MyCatalyst::Model::Token;

  use Moose;
  use namespace::autoclean;

  BEGIN { extends 'Catalyst::Model::Memcached' };

  __PACKAGE__->config( args => { servers => [ '127.0.0.1:11211' ], namespace => 'db' } );
  # Alternatively, this could be specified through config file

  __PACKAGE__->set_primary_key( qw/token/ );
  __PACKAGE__->set_ttl( 300 );

  sub BUILD {
    my $self = shift;
    $self->{__once_initialized_object} = Object->new;
    return $self;
  }

  sub create {
    my ($self, $hash) = @_;
    $hash->{token} = $self->{__once_initialized_object}->create_id();
    return $self->SUPER::create($hash)
  }

  1;

=head1 DESCRIPTION

Simple Model for Catalyst for storing data in memcached

=head1 USAGE

B<Warning> Module requires perl >= 5.10 and Catalyst >= 5.8 !

One subclass of model handle one set of primary_key and ttl params. 
You can think of it as one table in regular DB. 

In case you want to use memcached to store different entities through this 
model, you can configure it like this in config file:

  Model:
    Cached:
      class: MyApp::Store::Cached
      config:
        args:
          servers:
            - 127.0.0.1:11211
          namespace: 'db.'
        ttl: 86400

Assuming your model class is named MyApp::Model::Cached, your memcached 
server is started on localhost on port 11211. 
With this configuration all classes MyApp::Store::Cached::* 
will be loaded with same memcached configuration and default ttl of 86400. 

Primary key could be the same in different classes - to avoid clashes 
keys that are stored in memcached are constructed like 
'global_namespace.last_part_of_module_name.primary_key'.

=head1 METHODS

=over

=item create( hashref )

  $c->model( 'Cached::Token' )->create( 
    { token => 'aaaa', signature => 'abcd' } 
  );

Creates record in memcached with key = C<primary_key>, 
data = C<hashref>, expire = C<ttl>.
C<hashref> must contains C<primary_key>. 

=item search( hashref )

  $c->model( 'Cached::Token' )->search( { token => 'aaaa' } );

Searches data in memcached by C<primary_key> key and returns memcached answer.
C<hashref> must contains C<primary_key>.

=item find( hashref )

The same as search.

=item find_or_new( hashref )

Calls find, if nothing found - calls create.

=item delete( hashref )

Delete record with C<primary_key>.

=back

=head1 AUTHOR

    Denis Pokataev
    CPAN ID: CATONE
    Sponsored by Openstat.com
    catone@cpan.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Catalyst>, L<Cache::Memcached::Fast>, perl(1).

=cut


