#!/usr/bin/perl

package Catalyst::Plugin::Session::Store::Cache;
use base qw/Catalyst::Plugin::Session::Store/;

use strict;
use warnings;

our $VERSION = "0.01";

my $cache_key_prefix = "catalyst-plugin-session-store-cache:";

sub get_session_data {
    my ($c, $key) = @_;
    $c->cache->get($cache_key_prefix . $key);
}

sub store_session_data {
    my ($c, $key, $data) = @_;
    my $expires = $c->config->{session}{expires};
    $c->cache->set($cache_key_prefix . $key, $data, $expires);
}

sub delete_session_data {
    my ( $c, $key ) = @_;
    $c->cache->remove($cache_key_prefix . $key);
}

sub delete_expired_sessions { }

1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session::Store::Cache - Store sessions using a Catalyst::Plugin::Cache

=head1 SYNOPSIS

    use Catalyst qw/Cache::YourFavoriteCache Session Session::Store::Cache/;

=head1 DESCRIPTION

This plugin will store your session data in whatever cache module you
have configured.

=head1 METHODS

See L<Catalyst::Plugin::Session::Store>.

=over 4

=item get_session_data

=item store_session_data

=item delete_session_data

=item delete_expired_sessions

=back

=head1 AUTHOR

Lars Balker Rasmussen, E<lt>lbr@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Lars Balker Rasmussen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
