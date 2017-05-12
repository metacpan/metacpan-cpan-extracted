package AnyEvent::Memcached::Hash::WithNext;

=head1 NAME

AnyEvent::Memcached::Hash::WithNext - Hashing algorythm for AE::Memcached

=head1 SYNOPSIS

    my $memd = AnyEvent::Memcached->new(
        servers => [ "10.0.0.15:10001", "10.0.0.15:10002", "10.0.0.15:10003" ],
        # ...
        hasher  => 'AnyEvent::Memcached::Hash::WithNext',
    );
    $memd->set(key => "val", ...) # will put key on 2 servers

=head1 DESCRIPTION

Uses the same hashing, as default, but always put key to server, next after choosen. Result is twice-replicated data. Useful for usage with memcachdb

=cut

use common::sense 2;m{
use strict;
use warnings;
}x;
use Carp;
use base 'AnyEvent::Memcached::Hash';

sub peers {
	my $self = shift;
	my ($hash,$real,$peers) = @_;
	$peers ||= {};
	my $peer = $self->{buckets}->peer( $hash );
	my $next = $self->{buckets}->next( $peer );
	push @{ $peers->{$peer} ||= [] }, $real;
	push @{ $peers->{$next} ||= [] }, $real;
	return $peers;
}

=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=cut

1;