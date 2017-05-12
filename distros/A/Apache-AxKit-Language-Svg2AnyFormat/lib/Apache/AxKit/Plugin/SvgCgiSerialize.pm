package Apache::AxKit::Plugin::SvgCgiSerialize;

use strict;
use Apache::Constants qw(OK);

sub handler
{
    my $r  = shift;
    my %in = $r->args();
    
    if( $in{mime_type} )
    {
        $r->pnotes( 'axkit_mime_type', $in{mime_type} );
    }
    
    return OK;
}

1;

__END__

=pod

=head1 NAME 

Apache::AxKit::Plugin::SvgCgiSerialize - CGI-Parameter Plugin

=head1 SYNOPSIS

  AddHandler axkit .svg

  ## Fairly important to cache the output because
  ## transformation is highly CPU-Time and Memory consuming
  AxCacheDir /tmp/axkit_cache

  ## When using SvgCgiSerialize this is vital 
  ## because the cgi-parameters are not used
  ## by default to build the cache
  AxAddPlugin Apache::AxKit::Plugin::QueryStringCache

  <Files ~ *.svg>
    AxAddStyleMap application/svg2anyformat Apache::AxKit::Language::Svg2AnyFormat
    AxAddProcessor application/svg2anyformat NULL

    ## optional with this variable you can
    ## overwrite the default output format 
    ## PNG
    ## Supported Values:
    ##    image/jpeg
    ##    image/png
    ##    image/gif
    ##    application/pdf
    PerlSetVar SVGOutputMimeType image/jpeg
  
    ## optional module to pass the format using cgi-parameters
    ## to the module. For supported values see above
    ## and the man-page of the plugin
    AxAddPlugin Apache::AxKit::Plugin::SvgCgiSerialize   
  </Files>

=head1 DESCRIPTION

This plugin reads out the CGI-Parameter mime_type and passes it into the
Module.

=over

=item 

PNG: http://localhost/my.svg?mime_type=image/png

=item 

JPG: http://localhost/my.svg?mime_type=image/jpeg

=item 

GIF: http://localhost/my.svg?mime_type=image/gif

=item 

PDF: http://localhost/my.svg?mime_type=application/pdf

=back

=head1 VERSION

0.01

=head1 SEE ALSO

L<Apache::AxKit::Language::Svg2AnyFormat>

=head1 AUTHOR

Tom Schindl <tom.schindl@bestsolution.at>
