#!/usr/bin/perl

package Catalyst::Plugin::Cache::Store::FastMmap;

use strict;
use warnings;

our $VERSION = "0.02";

use Path::Class     ();
use File::Spec      ();
use Catalyst::Utils ();
use Catalyst::Plugin::Cache::Backend::FastMmap;

sub setup_fastmmap_cache_backend {
    my ( $app, $name, $config ) = @_;

    $config->{share_file} ||= File::Spec->catfile( Catalyst::Utils::class2tempdir($app), "cache_$name" );

    # make sure it exists
    Path::Class::file( $config->{share_file} )->parent->mkpath; 

    $app->register_cache_backend(
        $name => Catalyst::Plugin::Cache::Backend::FastMmap->new( %$config )
    );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Cache::Store::FastMmap - B<DEPRECATED> - FastMmap cache store
for L<Catalyst::Plugin::Cache>.

=head1 SYNOPSIS

    # instead of using this plugin, you can now do this:

    use Catalyst qw/
        Cache
    /;

    __PACKAGE__->config( cache => {
        backend => {
            class => "Cache:FastMmap",
            share_file => "/path/to/file",
            cache_size => "16m",
        },
    });

=head1 STATUS

This plugin is deprecated because L<Cache::FastMmap> no longer needs to be
wrapped to store plain values. It is still available on the CPAN for backwards
compatibility and will still work with newer versions of Cache::FastMmap with a
slight performance degredation.

=head1 DESCRIPTION

This store plugin is a bit of a wrapper for L<Cache::FastMmap>.

While you could normally just configure with

    backend => {
        class => "Cache::FastMmap",
        share_file => ...,
    }

L<Cache::FastMmap> can't store plain values by default. This module ships with
a subclass that will wrap all values in a scalar reference before storing.

This store plugin will try to provide a default C<share_file> as well, that
won't clash with other apps.

=head1 CONFIGURATION

See L<Catalyst::Plugin::Cache/CONFIGURATION> for a general overview of cache
plugin configuration.

This plugin just takes a hash reference in the backend field and passes it on
to L<Cache::FastMmap>.

=head1 SEE ALSO

L<Catalyst::Plugin::Cache>, L<Cache::FastMmap>.

=head1 AUTHOR

Yuval Kogman, C<nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

Copyright (c) Yuval Kogman, 2006. All rights reserved.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself, as well as under the terms of the MIT license.

=cut

