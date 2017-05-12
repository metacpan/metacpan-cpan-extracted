=head1 NAME

App::Basis::ConvertText2::Support

=head1 SYNOPSIS

=head1 DESCRIPTION

Support functions for L<App::Basis::ConvertText2> and its plugins

=cut

# ----------------------------------------------------------------------------

package App::Basis::ConvertText2::Support;
$App::Basis::ConvertText2::Support::VERSION = '0.4';
use 5.10.0;
use strict;
use warnings;
use Path::Tiny ;
use Digest::MD5 qw(md5_hex);
use Encode qw(encode_utf8);
use GD;
use Exporter;

use vars qw( @EXPORT @ISA);

@ISA = qw(Exporter);

# this is the list of things that will get imported into the loading packages
# namespace
@EXPORT = qw(
    cachefile
    create_sig
    create_img_src
);

# ----------------------------------------------------------------------------
# check if a file is in the cache, if so return the full file name
sub cachefile {
    my ($cache, $filename) = @_;

    # make sure we are working in the right dir
    return $cache . "/" . path($filename)->basename;
}


# ----------------------------------------------------------------------------
# create a signature based on content and params to a element
sub create_sig {
    my ( $content, $params ) = @_;
    my $param_str = join( ' ', map { "$_='$params->{$_}'"; } sort keys %$params );

    return md5_hex( $content . encode_utf8($param_str) );
}

# ----------------------------------------------------------------------------
# create a HTML img element using the passed in filename, also grab the
# image from the file and add its width and height to the attributes
sub create_img_src {
    my ( $file, $alt ) = @_;

    return "" if ( !$file || !-f $file );

    my $out = "<img src='$file' ";
    $out .= "alt='$alt' " if ($alt);

    my $image = GD::Image->new($file);
    if ($image) {
        $out .= "height='" . $image->height() . "' width='" . $image->width() . "' ";
    }

    $out .= "/>";
    return $out;
}

# ----------------------------------------------------------------------------

1;

__END__
