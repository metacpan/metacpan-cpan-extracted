package Dancer2::Plugin::SendAs;
# ABSTRACT: (DEPRECATED) Dancer2 plugin to send data as specific content type

use strict;
use warnings;

use Dancer2::Plugin;

use Class::Load 'try_load_class';
use Encode;
use List::Util 'first';

our $VERSION = '0.002'; # VERSION

register send_as => sub {
    my ( $dsl, $type, $data ) = @_;

    # allow lower cased serializer names
    my $serializer_class = first { try_load_class($_) }
                           map { "Dancer2::Serializer::$_" }
                           ( uc $type, $type );

    my %options = ();
    my $content;

    if ( $serializer_class ) {
        my $serializer = $serializer_class->new;
        $content = $serializer->serialize( $data );
        $options{content_type} = $serializer->content_type;
    }
    else {
        # send as HTML
        # TODO use content type of app
        $content = Encode::encode( 'UTF-8', $data );
        $options{content_type} = 'text/html; charset=UTF-8';
    }

    $dsl->app->send_file( \$content, %options );
}, { prototype => '$@' };

register_plugin;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dancer2::Plugin::SendAs - (DEPRECATED) Dancer2 plugin to send data as specific content type

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::SendAs;

    set serializer => 'YAML';
    set template => 'template_toolkit';

    get '/html' => sub {
        send_as html => template 'foo';
    };

    get '/json/**' => sub {
        send_as json => splat;
    };

=head1 DESCRIPTION

This plugin is DEPRECATED. The C<send_as> functionality was merged into
L<Dancer2> v0.200000.

A plugin to make it easy to return a specific content type from routes.

When an app has a serializer defined, returning HTML content is messy. You
could use C<send_file>, but need to take care of encoding yourself, adding
unnecessary boilerplate. Another solution is to split your app; resulting
in routes that return serialized content separated from routes that return
HTML. If there are a small number of routes (think O(1)) that return HTML,
splitting the app is tedious.

Conversly, returning serialized content from a small number of routes from
an app that otherwise returns HTML has similar issues.

This plugin provides a C<send_as> keyword, allowing content to be returned
from any available Dancer2 serializer, or HTML.

=head1 METHODS

=head2 send_as type => content

Send the content "serialized" using the specified serializer, or as HTML if no
matching serializer is found.

Any available Dancer2 serializer may be used. Serializers are loaded at runtime
(if necessary). Both the uppercase 'type' and the provided case of the type are
used to find an appropriate serializer class to use.

The implementation of C<send_as> uses Dancer2's C<send_file>. Your route will be
exited immediately when C<send_as> is executed. C<send_file> will stream
content back to the client if your server supports psgi streaming.

=head1 ACKNOWLEDGEMENTS

This module has been written during the
L<Perl Dancer 2015|https://www.perl.dance/> conference.

=head1 AUTHOR

Russell Jenkins <russellj@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Russell Jenkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
