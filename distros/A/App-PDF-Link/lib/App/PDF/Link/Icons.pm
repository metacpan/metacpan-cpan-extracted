#! perl

use strict;
use warnings;
use utf8;

package App::PDF::Link::Icons;

use Carp;
use parent qw(Exporter);

our @EXPORT = qw( load_icon_images get_icon );

my %icons;

sub _load_icon_images {

    my ( $env, $pdf ) = @_;

    my %idef =
      ( mscz	    => 'builtin:MuseScore',
	html	    => 'builtin:iRealPro',
	sib	    => 'builtin:Sibelius',
	xml	    => 'builtin:XML',
	abc	    => 'builtin:ABC',
      );

    if ( $env->{all} ) {
	$idef{biab} = 'builtin:BandInABox';
	$idef{jpg}  = 'builtin:JPG';
	$idef{png}  = 'builtin:PNG';
	$idef{pdf}  = 'builtin:PDF';
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

    while ( my ( $type, $file ) = each %idef ) {
	if ( $file =~ /^builtin:(.*)/ ) {
	    my $data
	      = eval( "require " . __PACKAGE__ . "::" . $1 . ";" .
		      "\\" . __PACKAGE__ . "::" . $1 . "::" . "icon();" );
	    croak("No icon data for $file") unless $data;
	    open( my $fd, '<:raw', $data );
	    my $p = $pdf->image_png($fd);
	    close($fd);
	    $icons{$type} = $p;
	    if ( $type eq 'jpg' ) {
		$icons{jpeg} = $p;
	    }
	    elsif ( $type eq 'jpeg' ) {
		$icons{jpg} = $p;
	    }
	    elsif ( $type eq 'biab' ) {
		for my $t ( qw( s m ) ) {
		    for my $i ( 0 .. 9, 'u' ) {
			$icons{sprintf("%sg%s", $t, $i)} = $p;
		    }
		}
	    }
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
    }

    return;
}

sub get_icon {
    my ( $env, $pdf, $ext ) = ( $_[0], $_[1], lc($_[2]) );

    _load_icon_images( $env, $pdf ) unless %icons;

    return $icons{$ext} if $icons{$ext};
    return $icons{' fallback'} if defined $icons{' fallback'};
    return;
}

# For testing.
sub __icons { \%icons };

1;
