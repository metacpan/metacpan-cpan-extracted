#!/usr/bin/perl

package Catalyst::Plugin::Images;

use strict;
use warnings;

use Image::Size ();
use HTML::Entities ();
use Path::Class ();
use MRO::Compat;

our $VERSION = "0.02";

sub setup {
    my $app = shift;
    my $ret = $app->next::method( @_ );

    $app->config->{images}{paths} ||= [
        $app->path_to(qw/root static/),
        $app->path_to(qw/root images/),
        $app->path_to(qw/root static images/),
    ];

    $app->config->{images}{uri_base} ||= $app->path_to("root");

    $ret;
}

sub image_tag {
    my ( $c, $basename, @attrs ) = @_;
    my %attrs = (@attrs == 1) ? %{ $attrs[0] } : @attrs;

    my $info = $c->get_image_info( $basename );
    
    foreach my $attr (qw/width height alt/) {
        next if exists $attrs{$attr};
        next unless exists $info->{$attr};
        $attrs{$attr} = $info->{$attr};
    }

    $attrs{src} = $info->{uri}->as_string;

    foreach my $tag ( keys %attrs ) {
        $attrs{$tag} = HTML::Entities::encode_entities( $attrs{$tag} )
            if $attrs{$tag} =~ /\D/;
    }

    return join(" ",
        '<img',
        (map { sprintf '%s="%s"', $_, $attrs{$_} } keys %attrs ),
        '/>'
    );
}

sub get_image_info {
    my ( $c, $basename ) = @_;

    if ( my $cached = $c->get_cached_image_info( $basename ) ) {
        return $cached;
    }
    
    my $path = $c->find_image_file( $basename );

    my $info = { ( $path ? $c->read_image_info( $path ) : () ) };

    $info->{path} = $path || Path::Class::file( $basename );
    $info->{uri}  = $c->image_path_to_uri( $path, $basename );

    $c->set_cached_image_info( $basename, $info );

    return $info;
}

sub get_cached_image_info {
    my ( $c, $basename ) = @_;
    return;
}

sub set_cached_image_info {
    my ( $c, $basename, $info ) = @_;
    return;
}

sub image_path_to_uri {
    my ( $c, $path, $basename ) = @_;
    $c->uri_for( "/" . ( $path ? $path->relative( $c->config->{images}{uri_base} ) : $basename ) );
}

sub find_image_file {
    my ( $c, $basename ) = @_;
   
    foreach my $path ( map { Path::Class::dir($_) } @{ $c->config->{images}{paths} } ) {
        $path = $c->path_to( $path ) unless $path->is_absolute;
        my $file = $path->file( $basename );
        return $file if -f $file->stringify;
    }

    $c->log->debug("Couldn't find an image by the name of '$basename' in any of the search paths")
        if $c->debug;

    return;
}

sub read_image_info {
    my ( $self, $path ) = @_;
    my ( $width, $height ) = eval { Image::Size::imgsize( $path->stringify ) };
    return ( width => $width || '', height => $height || '' );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Images - Generate image tags for static files.

=head1 SYNOPSIS

	use Catalyst qw/
        Images
    /;

    # ... somewhere in your templates

    [% c.image_tag("foo.png", alt => "alt text") %];

=head1 DESCRIPTION

This plugin provides a quick and easy way to include your images on the page,
automatically extracting and caching image metadata. It's automatically 
extendable, just pass whatever attribute you require as a key/value pair, and
it will be added to the image tag. It will also look through a preset of folders
so that you don't have to specify the full address to your image.

=head1 METHODS

=over 4

=item image_tag $basename, %attrs

This method generates an image tag for the image named $basename, with the
extra tags %attr automatically added to the resulting HTML tag. If you don't
specify height/width, it will be autodetected from the image.

=item get_image_info $basename

Retrieve the information about the image either from the cache or by searching
for it.

=item find_image_file $basename

Look inside all the search paths (see L</CONFIGURATION>) for an image named
$basename, and return the full path to it, as a <Path::Class::File> object..

=item read_image_info $path

Given the full path, as a L<Path::Class::File> object, return the attributes to
be added to the image. This returns a list with C<width> and C<height>, using
C<Image::Size>.

=item image_path_to_uri $path, $basename

Generates a URI using L<Catalyst/uri_for>, with the absolute path C<$path>
relativized to C<uri_base>. See L</CONFIGURATION>.

=item get_cached_image_info

=item set_cached_image_info

see L</CACHING IMAGE DATA> below.

=item setup

Overridden to seed configuration defaults.

=back

=head1 CONFIGURATION

All configuration information is stored under the C<images> key.

=over 4

=item paths

This should be an array reference of L<Path::Class::Dir> objects (easily
generated with L<Catalyst/path_to>) in which to search for images.

It defaults to C<root/static>, C<root/images>, C<root/static/images> by
default.

=item uri_base

This is the "base" prefix path for URI generation. For example, if an image was
found at C</www/static/images/foo.png> and C<uri_base> is C</www> then the
L<URI> generated with C<Catalyst/uri_for> will be for
C</static/images/foo.png>.

=back

=head1 CACHING IMAGE DATA

The code will call C<get_cached_image_info> and C<set_cached_image_info> when
appropriate. Currently both these operations are no op. You should override
this if you care.

C<get_cached_image_info> receives the base name, and should return the info
hash.

C<set_cached_image_info> receives the base name, and the info hash. It can use
this data to expire the cache based on mtime, etc. The info hash contains the
keys C<width>, C<height>, C<uri>, and C<path>.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Static::Simple>, L<Image::Size>

=head1 AUTHOR

Yuval Kogman, C<nothingmuch@woobling.org>

Last released by Tomas Doran, C<bobtfish@bobtfish.net>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
