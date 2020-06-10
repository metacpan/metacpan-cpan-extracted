#! perl

use strict;
use warnings;
use utf8;

package App::PDF::Link::Icons;

use Carp;
use parent qw(Exporter);
use App::Packager;

our @EXPORT = qw( load_icon_images get_icon );

my %icons;
my %idef;

sub _load_icon_images {

    my ( $env ) = @_;

    %idef =
      ( mscz	    => 'builtin:MuseScore',
	html	    => 'builtin:iRealPro',
	sib	    => 'builtin:Sibelius',
	xml	    => 'builtin:XML',
	mxl	    => 'builtin:MXL',
	musicxml    => 'builtin:MXL',
	abc	    => 'builtin:ABC',
      );

    if ( $env->{all} ) {
	$idef{jpg}  = 'builtin:JPG';
	$idef{jpeg} = 'builtin:JPG';
	$idef{png}  = 'builtin:PNG';
	$idef{pdf}  = 'builtin:PDF';
	$idef{biab} = 'builtin:BandInABox';
	for my $t ( qw( s m ) ) {
	    for my $i ( 0 .. 9, 'u' ) {
		$idef{sprintf("%sg%s", $t, $i)} = 'builtin:BandInABox';
	    }
	}
    }
    foreach ( keys %{ $env->{icons} } ) {
	if ( $env->{icons}->{$_} ) {
	    $idef{$_} = $env->{icons}->{$_};
	}
	else {
	    delete( $idef{$_} );
	}
    }
    $idef{' fallback'} = 'builtin:Document' if $env->{all};

    return;
}

sub get_icon {
    my ( $env, $pdf, $ext ) = ( $_[0], $_[1], lc($_[2]) );

    # Return the image object if we already have it.
    return $icons{$ext} if exists $icons{$ext};

    # Note. There's some work to do.
    _load_icon_images($env) unless %idef;

    my ( $type, $file ) = ( $ext, $idef{$ext} );
    if ( $file ) {
	if ( $file =~ /^builtin:(.*)/ ) {
	    my $data
	      = eval( "require " . __PACKAGE__ . "::" . $1 . ";" .
		      "\\" . __PACKAGE__ . "::" . $1 . "::" . "icon();" );
	    croak("No icon data for $file") unless $data;
	    open( my $fd, '<:raw', $data );
	    $icons{$type} = $pdf->image_png($fd);
	    close($fd);
	}
	else {
	    croak("$file: $!") unless -r $file;
	    if ( $file =~ /\.png$/i ) {
		$icons{$type} = $pdf->image_png($file);
	    }
	    elsif ( $file =~ /\.jpe?g$/i ) {
		$icons{$type} = $pdf->image_jpeg($file);
	    }
	    elsif ( $file =~ /\.gif$/i ) {
		$icons{$type} = $pdf->image_gif($file);
	    }
	    else {
		croak("$file: Unsupported file type");
	    }
	}
	foreach ( keys %idef ) {
	    $icons{$_} = $icons{$type} if $idef{$_} eq $file;
	}
    }
    return $icons{$ext} if $icons{$ext};
    return $icons{' fallback'} if defined $icons{' fallback'};
    return;
}

# For testing.
sub __icons {
    my $pdf = shift;
    get_icon( undef, $pdf, $_ ) for keys %idef;
    \%icons;
};

1;
