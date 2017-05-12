package Catalyst::Plugin::XSendFile;
use strict;
use warnings;
use base qw/Class::Data::Inheritable/;

use NEXT;
use MIME::Types;
use Path::Class qw/file/;

our $VERSION = '0.02';

=head1 NAME

Catalyst::Plugin::XSendFile - Catalyst plugin for lighttpd's X-Sendfile.

=head1 SYNOPSIS

    use Catalyst qw/XSendFile/;
    
    sub show : Path('/files') {
        my ( $self, $c, $filename ) = @_;
    
        # unless login, it shows 403 forbidden screen
        $c->res->status(403);
        $c->stash->{template} = 'error-403.tt';
    
        # serving a static file only when user logged in.
        if ($c->user) {
            $c->res->sendfile( "/path/to/$filename" );
        }
    }

=head1 DESCRIPTION

lighty's X-Sendfile feature is great.

If you use lighttpd + fastcgi, you can show files only set X-Sendfile header like below:

    $c->res->header( 'X-LIGHTTPD-send-file' => $filename );

This feature is especially great for serving static file on authentication area.

And with this plugin, you can use:

    $c->res->sendfile( $filename );

instead of above.

But off-course you know, this feature doesn't work on Catalyst Test Server (myapp_server.pl).
So this module also provide its emulation when your app on test server.

=head1 SEE ALSO

lighty's life - X-Sendfile
http://blog.lighttpd.net/articles/2006/07/02/x-sendfile

=head1 NOTICE

To use it you have to set "allow-x-sendfile" option enabled in your fastcgi configuration.

    "allow-x-send-file" => "enable",

=head1 EXTENDED_METHODS

=head2 setup

Setup MIME::Types object unless Static::Simple loaded.

=cut

sub setup {
    my $c = shift;
    $c->NEXT::setup(@_);

    unless ( $c->registered_plugins('Static::Simple') ) {
        __PACKAGE__->mk_classdata(
            _static_mime_types => MIME::Types->new( only_complete => 1 ) );
        __PACKAGE__->_static_mime_types->create_type_index;
    }

    $c;
}

=head2 finalize_headers

Added X-Sendfile emulation feature for test server.

=cut

sub finalize_headers {
    my $c = shift;

    # X-Sendfile emulation for test server.
    if ( ($ENV{CATALYST_ENGINE} || '') =~ /^HTTP/ ) {
        if ( my $sendfile = file( $c->res->header('X-LIGHTTPD-send-file') ) ) {
            $c->res->headers->remove_header('X-LIGHTTPD-send-file');
            if ( $sendfile->stat && -f _ && -r _ ) {
                my ($ext) = $sendfile =~ /\.(.+?)$/;
                my $user_types = $c->config->{static}->{mime_types};
                my $mime_type  = $user_types->{$ext}
                  || $c->_static_mime_types->mimeTypeOf($ext);
                $c->res->status(200);
                $c->res->content_type($mime_type);
                $c->res->body( $sendfile->openr );
            }
        }
    }

    $c->NEXT::finalize_headers;
}

=head1 EXTENDED_RESPONSE_METHODS

=head2 sendfile

Set X-LIGHTTPD-send-file header easily.

=cut

{
    package Catalyst::Response;

    sub sendfile {
        my ($self, $file) = @_;
        $self->header( 'X-LIGHTTPD-send-file' => $file );
    }
}

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
