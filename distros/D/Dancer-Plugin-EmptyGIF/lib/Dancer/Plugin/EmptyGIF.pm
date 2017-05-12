package Dancer::Plugin::EmptyGIF;

=head1 NAME

Dancer::Plugin::EmptyGIF - Quick empty GIF response

=head1 SYNOPSIS

 use Dancer;
 use Dancer::Plugin::EmptyGIF;
 
 get '/tracking/pixel.gif' => sub {
   # do something with params
   return empty_gif;
 }

=head1 METHODS

=head2 empty_gif

This will set your set your current request response to be an empty
gif, this means, it will return binary data for the image and
set the appropriate headers. You should always "return empty_gif".

=head1 WHY

An empty gif response is specially useful when you're building a
webservice that processes all the URL and/or query string parameters
and at the end, an empty gif needs to be returned to the client.
This a tracking or reporting pixel. Once the request has reached your
application code, it's better not to do any more redirections and
quickly return the empty pixel from within your code.

=head1 AUTHOR

David Moreno C<< <david at axiombox dot com> >>

=head1 CODE

L<http://github.com/damog/Dancer-Plugin-EmptyGIF>

=head1 LICENSE

Copyright, David Moreno, 2012

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

use Dancer ':syntax';
use Dancer::Plugin;
use MIME::Base64;

our $VERSION = '0.3';

register empty_gif => sub {
    header('Content-Type' => 'image/gif');
    header('Content-Disposition' => 'inline; filename="empty.gif"');
    decode_base64('R0lGODlhAQABAPAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==');
};

register_plugin;
1;
