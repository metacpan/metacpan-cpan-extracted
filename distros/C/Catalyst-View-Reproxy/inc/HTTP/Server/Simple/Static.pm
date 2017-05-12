#line 1
package HTTP::Server::Simple::Static;
use strict;
use warnings;

use File::MMagic ();
use MIME::Types  ();
use URI::Escape  ();
use IO::File     ();
use File::Spec::Functions qw(canonpath);

use base qw(Exporter);
our @EXPORT = qw(serve_static);

our $VERSION = '0.06';

my $mime  = MIME::Types->new();
my $magic = File::MMagic->new();

sub serve_static {
    my ( $self, $cgi, $base ) = @_;
    my $path = $cgi->url( -absolute => 1, -path_info => 1 );

    # Sanitize the path and try it.
    $path = $base . canonpath( URI::Escape::uri_unescape($path) );

    my $fh = IO::File->new();
    if ( -e $path and $fh->open($path) ) {
        binmode $fh;
        binmode $self->stdout_handle;

        my $content;
        {
            local $/;
            $content = <$fh>;
        }
        $fh->close;

        my $content_length;
        if ( defined $content ) {
            use bytes;    # Content-Length in bytes, not characters
            $content_length = length $content;
        }
        else {
            $content_length = 0;
            $content        = q{};
        }

        # If a file has no extension, e.g. 'foo' this will return undef
        my $mimeobj = $mime->mimeTypeOf($path);

        my $mimetype;
        if ( defined $mimeobj ) {
            $mimetype = $mimeobj->type;
        }
        else {

            # If the file is empty File::MMagic will give the MIME type as
            # application/octet-stream' which is not helpful and not the
            # way other web servers act. So, we default to 'text/plain'
            # which is the same as apache.

            if ($content_length) {
                $mimetype = $magic->checktype_contents($content);
            }
            else {
                $mimetype = 'text/plain';
            }
        }

        print "HTTP/1.1 200 OK\015\012";
        print 'Content-type: ' . $mimetype . "\015\012";
        print 'Content-length: ' . $content_length . "\015\012\015\012";
        print $content;
        return 1;
    }
    return 0;
}

1;
__END__

#line 139
