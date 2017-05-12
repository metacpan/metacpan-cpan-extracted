package Cache::Cascade; # git description: v0.06-3-g9cbe01e
# ABSTRACT: Get/set values to/from a group of caches, with some advanced semantics.

use strictures 2;
use Moo;
use Carp qw/croak/;
use Types::Standard qw(ArrayRef Bool);

sub _eval {
	my ( $code, %args ) = @_;
	$code =~ s/\[%\s*(\w+)\s*%\]/$args{$1} || die "$1 is not in eval" /ge;
	eval $code;
}

use namespace::autoclean;

our $VERSION = '0.07';

has caches => (
	isa => ArrayRef,
	is  => "rw",
);

has float_hits => (
	isa => Bool,
	is  => "rw",
	default => 0,
);

has set_deep => (
	isa => Bool,
	is  => "rw",
	default => 1,
);


sub get {
	my ( $self, $key ) = @_;

	if ( $self->float_hits ) {
		$self->get_and_float_result( $key, @{ $self->caches } );
	} else {
		foreach my $cache ( @{ $self->caches } ) {
			if ( defined( my $res = $cache->get($key) ) ) {
				return $res;
			}
		}

		return;
	}
}

sub get_and_float_result {
	my ( $self, $key, $head, @tail ) = @_;
	$head || return;

	if ( defined( my $res = $head->get($key) ) ) {
		return $res;
	} elsif ( @tail ) {
		if ( defined( my $res = $self->get_and_float_result( $key, @tail ) ) ) {
			$head->set( $key, $res );
			return $res;
		}
	}

	return;
}

sub set {
	my ( $self, $key, $value, @extra ) = @_;

	if ( $self->set_deep ) {
		$_->set($key, $value, @extra) for @{ $self->caches };
	} else {
		( $self->caches->[0] || return )->set($key, $value, @extra);
	}
}


BEGIN {
	foreach my $method (qw(size count)) {
		_eval <<'CODE', method => $method;
sub [% method %] {
	my $self = shift;
	return $self->_sum_[% method %]( @{ $self->caches } )
}

sub _sum_[% method %] {
	my ( $self, $head, @tail ) = @_;
	$head || return 0;
	$head->[% method %] + $self->_sum_[% method %]( @tail );
}
CODE
	}

	foreach my $method (qw(remove clear set_load_callback set_validate_callback)) {
		_eval <<'CODE', method => $method;
sub [% method %] {
	my ( $self, @args ) = @_;
	$_->[% method %]( @args ) for @{ $self->caches };
}
CODE
	}

	foreach my $method (qw(entry exists load_callback validate_callback)) {
		_eval <<'CODE', method => $method;
sub [% method %] {
	my ( $self, @args ) = @_;

	foreach my $cache ( @{ $self->caches } ) {
		if ( my $res = $cache->[% method %]( @args ) ) {
			return $res;
		}
	}

	return;
}
CODE
	}
}

__PACKAGE__;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cache::Cascade - Get/set values to/from a group of caches, with some advanced semantics.

=head1 VERSION

version 0.07

=head1 SYNOPSIS

	use Cache::Cascade;

	Cache::Cascade->new(
		caches => [
			Cache::Bounded->new(...),
			Cache::FastMmap->new(...),
			Cache::Memcached->new(...),
		],
		float_hits => 1,
		set_deep   => 1,
	);

=head1 DESCRIPTION

=for stopwords tradeoff multiserver MemoryCache FastMmap

In a multiprocess, and especially a multiserver application caching is a very
effective means of improving results.

The tradeoff of increasing the scale of the caching is in added complexity.
For example, caching in a FastMmap based storage is much slower than using a
memory based cache, because pages must be locked to ensure that no corruption
will happen. Likewise Memcached is even more overhead than FastMmap because it
is network bound, and uses blocking IO (on the client side).

This module attempts to make a transparent cascade of caches using several
backends.

The idea is to search from the cheapest backend to the most expensive, and
depending on the options also cache results in the cheaper backends.

The benefits of using a cascade are that if the chance of a hit is much higher
in a slow cache, but checking a cheap cache is negligible in comparison, we
may already have the result we want in the cheap cache. Configure your
expiration policy so that there is approximately an order of magnitude better
probability of cache hits (bigger cache) for each level of the cascade.

=head1 FIELDS

=over 4

=item set_deep

Defaults to true. See C<set>.

=item float_hits

Defaults to false. See C<get>.

=back

=head1 METHODS

=over 4

=item get $key

This method will delegate C<get> to every cache object in order, and return the first match.

Additionally, if C<float_hits> is set to a true value, it will also call C<set>
with the match on every cache object before the one that matched.

=item set $key, $value

If C<set_deep> is set to a true value this method will delegate C<set> to every
cache object in the list.

If C<set_deep> is set to a false value this method will delegate C<set> just to
the first cache object in the list.

=item remove $key

=item clear

These methods will delegate C<remove> on every cache object in the list.

=item entry $key

=item exists $key

Returns the first match.

=item clear

=item size

=item count

These two methods are sum based aggregates.

=item validate_callback

=item load_callback

These two methods return the first callback they found.

=item set_load_callback

=item set_validate_callback

These two methods set the callback for all the caches.

=item get_and_float_result $key, @caches

This is used to implement the C<float_hits> behavior of C<get> recursively.

=back

=head1 CAVEATS

When you set or remove a key from the cascade and this propagates downwards, for
example from MemoryCache to FastMmap, other cascades will not notice the change
until their own MemoryCache is expired.

Thus, if cache invalidation is important in your algorithm (data changes) do
not use a cascade. If stale hits are permitted, or the cache is for non
changing data then you should use a cascade.

=head1 SEE ALSO

L<Cache>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Cache-Cascade>
(or L<bug-Cache-Cascade@rt.cpan.org|mailto:bug-Cache-Cascade@rt.cpan.org>).

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2006 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
