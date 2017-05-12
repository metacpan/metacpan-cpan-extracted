#
# $Id: Weak.pm 22 2008-04-22 13:28:19Z esobchenko $
package Cache::Weak;

use strict;
use warnings;

use version; our $VERSION = qv('1.0.3');

use Carp qw/carp croak/;
use Scalar::Util qw/weaken/;

use constant {
	DEFAULT_NAMESPACE => '_',
	DEFAULT_AUTO_PURGE_INTERVAL => 1000,
	DEFAULT_AUTO_PURGE => 1,
};

# data is stored in the form: $cache_data{$namespace}{$key} = $object
my %cache_data = ();
my %cache_meta = ();

# private method: used in constructor to get it's arguments
sub _get_args {
	my $proto = shift;

	my $args;
	if ( scalar(@_) > 1 ) {
		if ( @_ % 2 ) {
			croak "odd number of parameters";
		}
		$args = { @_ };
	} elsif ( ref $_[0] ) {
		unless ( eval { local $SIG{'__DIE__'}; %{ $_[0] } || 1 } ) {
			croak "not a hashref in args";
		}
		$args = $_[0];
	} else {
		$args = { namespace => shift };
	}

	return $args;
}

sub new {
	my $class = shift;
	my $self = $class->_get_args(@_);
	return bless $self, $class;
}

sub namespace {
	my $self = shift;
	if (@_) {
		$self->{namespace} = shift;
	}
	return $self->{namespace} || DEFAULT_NAMESPACE;
}

sub auto_purge_interval {
	my $self = shift;
	if (@_) {
		$self->{auto_purge_interval} = shift;
	}
	return $cache_meta{ $self->namespace }{auto_purge_interval}
		= defined $self->{auto_purge_interval} ?
		$self->{auto_purge_interval} : DEFAULT_AUTO_PURGE_INTERVAL;
}

sub auto_purge {
	my $self = shift;
	if (@_) {
		$self->{auto_purge} = shift;
	}
	return $cache_meta{ $self->namespace }{auto_purge}
		= defined $self->{auto_purge} ?
		$self->{auto_purge} : DEFAULT_AUTO_PURGE;
}

# private method: increment access counter for the given namespace and return it's value
sub _inc_count {
	my $self = shift;
	return $cache_meta{ $self->namespace }{count} += 1;
}

# private method: return actual keys for current namespace
sub _keys {
	my $self = shift;
	return keys %{ $cache_data{ $self->namespace } };
}

sub count {
	my $self = shift;
	return int scalar $self->_keys;
}

sub get {
	my ( $self, $key ) = @_;
	return $cache_data{ $self->namespace }{$key};
}

sub set {
	my ( $self, $key, $object ) = @_;

	croak "attempting to set non-reference value" unless ref $object;

	# is it time to purge cache from dead objects?
	if ( $self->auto_purge ) {
		$self->purge unless ( $self->_inc_count % $self->auto_purge_interval );
	}

	weaken ( $cache_data{ $self->namespace }{$key} = $object );
	return 1;
}

sub remove {
	my ( $self, $key ) = @_;
	delete $cache_data{ $self->namespace }{$key};
	return 1;
}

# XXX "exists" actually means "defined" in our case
sub exists {
	my ( $self, $key ) = @_;
	return defined $cache_data{ $self->namespace }{$key};
}

sub purge {
	my $self = shift;
	my $cache = $cache_data{ $self->namespace };
	delete @{ $cache }{ grep !$self->exists($_), $self->_keys };
	return 1;
}

sub clear {
	my $self = shift;
	delete $cache_data{ $self->namespace };
	delete $cache_meta{ $self->namespace };
	return 1;
}

1;

__END__

=head1 NAME

Cache::Weak - weak reference cache

=head1 VERSION

This documentation refers to Cache::Weak version 1.0.2

=head1 SYNOPSIS

	use Cache::Weak;
	my $cache = Cache::Weak->new();

=head1 DESCRIPTION

This cache will store it's objects without increase the reference
count. This can be used for caching without interfere in objects DESTROY
mechanism, since the reference in this cache won't count.

=head1 CONSTRUCTOR

You can pass a number of options to the constructor to specify things like namespace, etc.
This is done by passing an inline hash (or hashref):

	my $cache = Cache::Weak->new( namespace => 'foo' );

See "PROPERTIES" below for a list of all available properties that can be set.

=head1 METHODS

=over

=item set

	$cache->set($key, $object);

Store specified key/value pair in cache. Value must be a reference.

=item get

	my $object = $cache->get($key);

Search cache for given key. Returns undef if not found.

=item exists

	my $bool = $cache->exists($key);

Returns a boolean value to indicate whether there is any data present in the cache for specified entry.

=item remove

	$cache->remove($key)

Clear the data for specified entry from the cache.

=item purge

	$cache->purge();

Weak references are not removed from the cache when last "real" object goes out of
scope. This means that over time the cache will grow in memory. C<purge()> will remove all
dead references from cache. Usually you don't have to run C<purge()> manually: purging is done
automatically. By default, this happens every 1000 object loads, but you can change that
default by setting the 'auto_purge_interval' and 'auto_purge' properties.

=item clear

	$cache->clear();

Removes all entries from cache.

=item count

	$cache->count();

Returns the number of entries in the cache.

=back

=head1 PROPERTIES

=over

=item I<namespace>

	my $current_ns = $cache->namespace();

The namespace associated with this cache. Defaults to "_" if not explicitly set.

=item I<auto_purge_interval>

	$cache->auto_purge_interval(5000);

Sets number of cache object loads before auto purging is automatically performed. Default is 1000.

=item I<auto_purge>

	$cache->auto_purge(0); # turn off auto purge

If this option is true, then the auto purge interval will be checked on every C<set()>.

=back

=head1 DEPENDENCIES

This module requires weak references support in your system.
To find out if your system supports weak references, you can run this on the command line:

	perl -e 'use Scalar::Util qw(weaken)'

If you get an error message about weak references not being implemented, this module would
not work.

=head1 SEE ALSO

L<http://github.com/esobchenko/cache-weak/> this module on GitHub.

L<http://en.wikipedia.org/wiki/Weak_reference> about weak references.

L<Scalar::Util> for information about weak references in Perl.

L<Object::Mapper> for an example of this module in use.

=head1 LICENSE AND COPYRIGHT

Copyright 2008, Eugen Sobchenko <ejs@cpan.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

