package Apache::AxKit::Language::Svg2AnyFormat;

@ISA = ( 'Apache::AxKit::Language' );

BEGIN {
   $Apache::AxKit::Language::Svg2AnyFormat::VERSION = 0.06
}

use Apache;
use Apache::Request;
use File::Copy ();
use File::Temp ();
use File::Path ();
use Cwd;
use strict;
use warnings;

my $TEMPDIR_;

my %Config = 
(  
    SVGOutputMimeType   => "image/png",
    SVGOutputSerializer => "ImageMagick"
);

my %MimeTypeSuffixFormatMappings =
(
    "image/png"              => [ "png" , "png"  ],
    "image/jpeg"             => [ "jpg" , "jpeg" ],
    "image/gif"              => [ "gif" , "gif"  ],
    "image/tiff"             => [ "tiff", "tiff" ],
    "application/pdf"        => [ "pdf" , "pdf"  ],
    "application/postscript" => [ "eps" , "eps"  ]
);


sub stylesheet_exists () { 0; }

sub handler
{
    my $class = shift;
    my ( $r, $xml_provider, undef, $last_in_chain ) = @_;
    
    my $mime;
    my $suffix;
    my $serializer;
    my $serialized_svg;
    my $temp_svg;
    
    AxKit::Debug(8, "Transform started!!!!");
    
    if( ! $last_in_chain ) {
        fail( "This is a Serializer, hence it has to be the last in the chain!" );
    }

    ( $mime, $suffix ) = &mimeTypeSuffixHandling( $r );
    
    AxKit::Debug(8, "MimeType is set to '$mime'");
    AxKit::Debug(8, "Suffix is set to '$suffix'");
    
    $serializer = $r->dir_config( "SVGOutputSerializer" ) || $Config{SVGOutputSerializer};
        
    $temp_svg = &createTempSVGFile( $r, $xml_provider );
    
    if( $serializer eq "ImageMagick" ) {
        $serialized_svg = &serializeWithImageMagick( $temp_svg, $suffix );
    } elsif( $serializer eq "LibRSVG" ) {
        AxKit::Debug(8, "Serializer is: LibRSVG");
        $serialized_svg = &serializeWithLibRSVG( $temp_svg, $MimeTypeSuffixFormatMappings{$mime}->[1], $suffix );
    } else {
        fail( "This is an unknown serializer for me." );
    }

    AxKit::Debug(8, "Serialization finished.");

    $AxKit::Cfg->AllowOutputCharset(0);
    
    my $pdfh = Apache->gensym();
    
    open( $pdfh, "<$serialized_svg" ) or fail( "Could not open $serialized_svg: $!" );
    $r->content_type( $mime );
    local $/;
    
    $r->print(<$pdfh>);
    
    &cleanup();
    
    return Apache::Constants::OK;
}

sub serializeWithLibRSVG {
    my $infile         = shift;
    my $format         = shift;
    my $suffix         = shift;
    my $converted_file = "$TEMPDIR_/temp." . $suffix;
    
    require Image::LibRSVG;
    
    my $rsvg = new Image::LibRSVG();
    
    if( Image::LibRSVG->isFormatSupported( $format ) ) {
        if( ! $rsvg->convert( $infile, $converted_file, 0, $format ) ) {
            fail( "The was an error when transforming with Image::LibRSVG\n" );
        }
    } else {
        if( ! $rsvg->convert( $infile, "$TEMPDIR_/temp.png" ) ) {
            fail( "The was an error when transforming with Image::LibRSVG\n" );
        } else {
#	    print STDERR "FORMAT $format NOT SUPPORTED BY Image::LibRSVG\n";
            &serializeWithImageMagick( "$TEMPDIR_/temp.png", $suffix );
        }
    }
    
    return $converted_file;
}

sub serializeWithImageMagick {
    my $infile         = shift;
    my $converted_file = "$TEMPDIR_/temp." . shift;
    my $local_dir;
    
    require Image::Magick;
    
    AxKit::Debug(8, "Serializer is ImageMagick");
    
    $infile =~ s%$TEMPDIR_/%%;
    $local_dir = cwd;
    
    chdir( $TEMPDIR_ );
    
    my $image = new Image::Magick();
    my $retval = $image->Read( $infile );
        
    if( "$retval" ) {
        chdir( $local_dir );
        fail( "ImageMagick Read of file '$infile' failed. Reason: $retval" );
    }
        
    $retval = $image->Write( $converted_file );
    
    if( "$retval" ) {
        chdir( $local_dir );
        fail( "ImageMagick Write of file '$converted_file' failed. Reason: $retval" );
    }
    
    chdir( $local_dir );
    
    return $converted_file;
}


sub createTempSVGFile {
    my $r            = shift;
    my $xml_provider = shift;
    my $temp_svg;
    my $fh;
    my $xmlstring;
    
    $TEMPDIR_ = File::Temp::tempdir();
    
    AxKit::Debug(8, "Got tempdir: $TEMPDIR_");
    
    if ( ! $TEMPDIR_ ) {
        die "Cannot create tempdir: $!";
    } else {
        $temp_svg = "$TEMPDIR_/temp.svg";
        $fh = Apache->gensym();
    }
    
    if( my $dom = $r->pnotes('dom_tree') )
    {
        AxKit::Debug(8, "Got a dom tree");
        
        $dom->toFile("$TEMPDIR_/temp.svg");
        delete $r->pnotes()->{'dom_tree'};
        
    } elsif( $xmlstring = $r->pnotes('xml_string') ) {
        AxKit::Debug(8, "Got a xml-string");
        
        open($fh, ">$TEMPDIR_/temp.svg") || fail( "Cannot write: $!" );
            print $fh $xmlstring;
        close( $fh ) || fail( "Cannot close: $!" );
        
    } else {
        $xmlstring = eval { ${$xml_provider->get_strref()} };
        
        if ( $@ ) {
            AxKit::Debug(8, "No ref");
            $fh = $xml_provider->get_fh();

            File::Copy::copy($fh, "$TEMPDIR_/temp.svg");
        } else  {
            AxKit::Debug(8, "It has been a ref");
            
            open($fh, ">$TEMPDIR_/temp.svg") || fail( "Cannot write: $!" );
                print $fh $xmlstring;
            close($fh) || fail("Cannot close: $!");
            
        }
    }
    
    return $temp_svg;
}


sub mimeTypeSuffixHandling {
    my $r = shift;
    my $mime;
    my $suffix;
    
    if( $r->pnotes( "axkit_mime_type" ) ) {
        AxKit::Debug(8, "MimeType retrieved from Plugin");
        $mime = $r->pnotes( "axkit_mime_type" );
    } else {
        AxKit::Debug(8, "MimeType retrieved from CONF or using Default");
        $mime = $r->dir_config( "SVGOutputMimeType" ) || $Config{SVGOutputMimeType};
    }
    
    if( ! exists $MimeTypeSuffixFormatMappings{$mime} ) {
        AxKit::Debug(8, "MimeType is not known. We are using DEFAULTS");
        $mime   = $Config{SVGOutputMimeType};
        $suffix = "png";
    } else {
        AxKit::Debug(8, "Setting suffix. To mapped value");
        $suffix = $MimeTypeSuffixFormatMappings{$mime}[0];
    }
    
    return ( $mime, $suffix );
}

sub cleanup {
    File::Path::rmtree( $TEMPDIR_ );
}

sub fail {
    &cleanup();
    die @_;
}

1;


__END__

=pod

=head1 NAME

Apache::AxKit::Language::Svg2AnyFormat - SVG Serializer

=head1 SYNOPSIS

=head2 ImageMagick

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

=head2 LibRSVG

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
    ## Supported Values(Native Formats):
    ##    image/png
    ## If you specify any other format:
    ##   svg->png is done by Image::LibRSVG
    ##   png->chosen format Image::Magick
    PerlSetVar SVGOutputMimeType image/jpeg
    
    PerlSetVar SVGOutputSerializer LibRSVG
    
    ## optional module to pass the format using cgi-parameters
    ## to the module. For supported values see above
    ## and the man-page of the plugin
    AxAddPlugin Apache::AxKit::Plugin::SvgCgiSerialize   
  </Files>


=head1 DESCRIPTION

Svg2AnyFormat is a serializer which can transform SVG to many different
output formats(e.g. png, jpg, ... ). At the moment it uses Image::Magick or LibRSVG as conversion libraries
which do not support the whole set of svg features. In one case the conversion
could work in another not. You have to give it a try. Please note because 
Svg2AnyFormat to any format is a searializer it HAS TO BE LAST in the transformer 
chain!!!!

Please note when referencing external material (e.g. Images) you'll have to use an absolute path

=head2 Image::Magick

If no SVGOutputSerializer is set Image::Magick is used as default. The reason is simply
because of backward compatility. You could also set Image::Magick explicitly with

=head3 Example:

  PerlSetVar SVGOutputSerializer ImageMagick

=head3 Advantges:

=over

=item 

Nearly any format can be exported

=item 

known to work on many os

=back

=head3 Disadvantages:

=over

=item 

it's fairly big

=item 

it does not support as much of the SVG-Spec as LibRSVG

=back

=head2 LibRSVG

LibRSVG is part of the gnome project. And could also be used as SVG-Serializer at the moment
the only really supported output-format is PNG. As a matter of that if you want to use
LibRSVG as your SVG-Serializer and the output format is an other than PNG, LibRSVG is used to
transform the SVG to PNG and ImageMagick from PNG to the desired output format.

=head3 Example:

  PerlSetVar SVGOutputSerializer LibRSVG

=head3 Advantages

=over

=item 

supports more of SVG-spec than Image::Magick

=item

not that big

=back

=head3 Disadvantages:

=over

=item 

* Perl-Module highly experimental

=item

only PNG supported as output format. This is solved by using
Image::Magick in a second transformation step (LOW Performance!!!).

=back

=head1 VERSION

0.03

=head1 SEE ALSO

L<Apache::AxKit::Plugin::SvgCgiSerialize>

=head1 AUTHOR

Tom Schindl <tom.schindl@bestsolution.at>

=cut
