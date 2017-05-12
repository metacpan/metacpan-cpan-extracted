package Catalyst::Plugin::AutoCRUD::Controller::Static;
{
  $Catalyst::Plugin::AutoCRUD::Controller::Static::VERSION = '2.143070';
}

use strict;
use warnings;

use base 'Catalyst::Controller';

use File::stat;
use File::Basename;
use File::Slurp;

my %mime = (
    css => 'text/css',
    gif => 'image/gif',
    png => 'image/png',
    js  => 'application/x-javascript',
);

# erm, this is a bit naughty. it's basically Catalyst::Plugin::Static on the
# cheap. there are a couple of nice icons we want to make sure the users have
# but it'd be too much hassle to ask them to install, so we bundle them.
#
sub cpacstatic : Chained('/autocrud/root/base') Args {
    my ($self, $c, @target) = @_;
    my $file = join '/', @target;
    $c->log->debug("Static request for file [$file], generated from parts")
        if scalar @target > 1 and $c->debug;

    (my $pkg_path = __PACKAGE__) =~ s{::}{/}g;
    my (undef, $directory, undef) = fileparse(
        $INC{ $pkg_path .'.pm' }
    );

    my $path = "$directory../static/$file";

    if ( ($file =~ m/\w+\.(\w{2,3})$/i) and (-f $path) ) {
        my $ext = $1;
        my $stat = stat($path);

        if ( $c->req->headers->header('If-Modified-Since') ) {

            if ( $c->req->headers->if_modified_since == $stat->mtime ) {
                $c->res->status(304); # Not Modified
                $c->res->headers->remove_content_headers;
                return 1;
            }
        }

        if (!exists $mime{$ext}) {
            $c->log->debug(qq{No mime type for "$file"}) if $c->debug;
            $c->res->status(415);
            return 0;
        }

        my $content = read_file( $path, binmode => ':raw' );
        $c->res->headers->content_type($mime{$ext});
        $c->res->headers->content_length( $stat->size );
        $c->res->headers->last_modified( $stat->mtime );
        $c->res->output($content);
        if ( $c->config->{static}->{no_logs} && $c->log->can('abort') ) {
           $c->log->abort( 1 );
        }
        $c->log->debug(sprintf "Serving file [%s] of size [%s] as [%s]",
            $file, $stat->size, $c->res->headers->content_type) if $c->debug;
        $c->res->status(200);
        return 1;
    }

    $c->log->debug(qq{Failed to serve file [$file] from [$path]}) if $c->debug;
    $c->res->status(404);
    return 0;
}

1;
__END__
