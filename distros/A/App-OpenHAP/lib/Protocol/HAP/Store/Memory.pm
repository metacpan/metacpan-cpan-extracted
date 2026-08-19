# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Protocol::HAP::Store::Memory;
our $VERSION = '0.1.0';

# Protocol::HAP::Store::Memory - the store contract over plain hashes.
#
# This is the reference implementation of the twelve store methods
# that Protocol/HAP/Store.pod documents. Nothing persists: the state
# lives in the object and dies with it. Tests and embedders start
# here; a production host implements the same contract over durable
# storage.
#
# The mutating pairing methods increment the configuration number
# themselves. A store that skips the increment breaks c# in one
# direction; an engine that adds one on top breaks it in the other.

sub new ($class)
{
	return bless {
		ltsk          => undef,
		ltpk          => undef,
		pairings      => {},
		config_number => 1,
		config_digest => undef,
		auth_attempts => 0,
	}, $class;
}

# $self->load_accessory_keys:
#	Return ($ltsk, $ltpk), or the empty list when no identity is
#	stored yet.
sub load_accessory_keys ($self)
{
	return () unless defined $self->{ltsk} && defined $self->{ltpk};

	return ( $self->{ltsk}, $self->{ltpk} );
}

sub save_accessory_keys ( $self, $ltsk, $ltpk )
{
	$self->{ltsk} = $ltsk;
	$self->{ltpk} = $ltpk;

	return;
}

# $self->load_pairings:
#	Return the pairings as a hash reference keyed by controller
#	id. Each value holds ltpk and permissions.
sub load_pairings ($self)
{
	# A copy, so a caller that edits the result cannot bypass the
	# increment rule of the mutating methods
	return {
		map { $_ => { %{ $self->{pairings}{$_} } } }
		    keys %{ $self->{pairings} } };
}

sub save_pairing ( $self, $controller_id, $ltpk, $permissions = 1 )
{
	$self->{pairings}{$controller_id} = {
		ltpk        => $ltpk,
		permissions => $permissions,
	};
	$self->increment_config_number;

	return;
}

sub remove_pairing ( $self, $controller_id )
{
	delete $self->{pairings}{$controller_id};
	$self->increment_config_number;

	return;
}

sub remove_all_pairings ($self)
{
	$self->{pairings} = {};
	$self->increment_config_number;

	return;
}

# The configuration number starts at 1 and only ever goes up. A
# controller that sees it go backwards drops the accessory.
sub get_config_number ($self)
{
	return $self->{config_number};
}

sub increment_config_number ($self)
{
	return ++$self->{config_number};
}

sub get_config_digest ($self)
{
	return $self->{config_digest};
}

sub save_config_digest ( $self, $digest )
{
	$self->{config_digest} = $digest;

	return;
}

sub get_auth_attempts ($self)
{
	return $self->{auth_attempts};
}

sub set_auth_attempts ( $self, $count )
{
	$self->{auth_attempts} = $count;

	return;
}

1;
