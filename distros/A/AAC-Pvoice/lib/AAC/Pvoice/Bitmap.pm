package AAC::Pvoice::Bitmap;

use strict;
use warnings;
use Wx qw(:everything);
use Wx::Perl::Carp;
use Image::Magick;
use IO::Scalar;
use File::Cache;
use File::stat;
use File::Temp qw( :POSIX );

our $VERSION     = sprintf("%d.%02d", q$Revision: 1.12 $=~/(\d+)\.(\d+)/);

use base qw(Wx::Bitmap);
our $cache;
BEGIN
{
    Wx::InitAllImageHandlers;
    $cache = File::Cache->new({namespace => 'images'});
}

#----------------------------------------------------------------------
sub new
{
    my $class = shift;
    my ($file, $MAX_X, $MAX_Y, $caption, $background, $blowup, $parent_background) = @_;
    $caption||='';
    $parent_background=Wx::Colour->new(220,220,220) if not defined $parent_background;
    my $config = Wx::ConfigBase::Get;
    $caption = $config->ReadInt('Caption')?$caption:'';
#    return ReadImage($file, $MAX_X, $MAX_Y, $caption, $background, $blowup, $parent_background) if $file;
    return ReadImageMagick($file, $MAX_X, $MAX_Y, $caption, $background, $blowup, $parent_background) if $file;
    return DrawCaption($MAX_X, $MAX_Y, $caption, $background, $parent_background);
}


sub ReadImage
{
    my $file = shift;
    my ($x, $y, $caption, $background, $blowup, $parent_background) = @_;
    return DrawCaption($x, $y, '?', $background, $parent_background) unless -r $file;
    confess "MaxX and MaxY should be positive" if $x < 1 || $y < 1;
    my $newbmp;
    
    $caption ||='';
    $blowup ||=0;
    $background = $parent_background unless defined $background;

    my $ibg = wxColor2hex($background) if (ref($background) eq 'Wx::Colour');
    my $pbg = wxColor2hex($parent_background) if (ref($parent_background) eq 'Wx::Colour');

    my $stat = stat($file);
    my $mtime = $stat->mtime();
    my $image = $cache->get("$file-$x-$y-$caption-$ibg-$blowup-$pbg-$mtime");
    if (!$image)
    {
        my $capdc = Wx::MemoryDC->new();
        my $cpt = 10;
        my ($cfont, $cw, $ch) = (wxNullFont, 0, 0);
        if ($caption)
        {
            do
            {
                $cfont = Wx::Font->new( $cpt,               # font size
                                        wxSWISS,            # font family
                                        wxNORMAL,           # style
                                        wxNORMAL,           # weight
                                        0,                  
                                        'Comic Sans MS',    # face name
                                        wxFONTENCODING_SYSTEM);
                ($cw, $ch, undef, undef) = $capdc->GetTextExtent($caption, $cfont);
                $cpt--;
            } until ($cw<$x);
        }
        my $img = Wx::Image->new($x, $y-$ch);
        $img->SetOption('quality', 100);
        my $rc = $img->LoadFile($file, wxBITMAP_TYPE_ANY);
        return wxNullBitmap if not $rc;
        my ($w,$h) = ($img->GetWidth, $img->GetHeight);
        if (($w > $x) || ($h > ($y-$ch)))
        {
            my ($newx, $newy) = ($w, $h);
            if ($w > $x)
            {
                my $factor = $w/$x;
                return wxNullBitmap if not $factor;
                $newy = int($h/$factor);
                ($w,$h) = ($x, $newy);
            }
            if ($h > ($y-$ch))
            {
                my $factor = $h/($y-$ch);
                return wxNullBitmap if not $factor;
                ($w, $h) = (int($w/$factor),$y-$ch);
            }
            $img = $img->Scale($w, $h);
        }
        elsif ($blowup)
        {
            # Do we really want to blow up images that are too small??
            my $factor = $w/$x;
            return wxNullBitmap if not $factor;
            my $newy = int($h/$factor);
            ($w,$h) = ($x, $newy);
            if ($h > ($y-$ch))
            {
                my $factor = $h/($y-$ch);
                return wxNullBitmap if not $factor;
                ($w, $h) = (int($w/$factor),$y-$ch);
            }
            $img = $img->Scale($w, $h);
        }
        my $bmp = Wx::Bitmap->new($img);
        my $newbmp = Wx::Bitmap->new($x, $y);
        my $tmpdc = Wx::MemoryDC->new();
        $tmpdc->SelectObject($newbmp);
    
        my $bgbr = Wx::Brush->new($parent_background, wxSOLID);
        $tmpdc->SetBrush($bgbr); 
        $tmpdc->SetBackground($bgbr);
        $tmpdc->Clear();
    
        my $bg = $parent_background;
        if (defined $background)
        {
            if (ref($background)=~/ARRAY/)
            {
                $bg = Wx::Colour->new(@$background);
            }
            else
            {
                $bg = $background;
            }
            my $br = Wx::Brush->new($bg, wxSOLID);
            my $pen = Wx::Pen->new($bg, 1, wxSOLID);
            $tmpdc->SetBrush($br);
            $tmpdc->SetPen($pen);
            $tmpdc->DrawRoundedRectangle(1,1,$x-1,$y-1, 10);
        }
    
        my $msk = Wx::Mask->new($bmp, Wx::Colour->new(255,255,255));
        $bmp->SetMask($msk);
        $tmpdc->DrawBitmap($bmp, int(($x - $bmp->GetWidth())/2), int(($y-$ch-$bmp->GetHeight())/2), 1);
    
        if ($caption)
        {
            $tmpdc->SetTextBackground($bg);
            $tmpdc->SetTextForeground(wxBLACK);
            $tmpdc->SetFont($cfont);
            $tmpdc->DrawText($caption, int(($x-$cw)/2),$y-$ch);
        }
        my $tmpfile = File::Temp::tmpnam();
    	$newbmp->SaveFile($tmpfile, wxBITMAP_TYPE_PNG);
        local $/ = undef;
        open(my $fh, "<$tmpfile");
        binmode($fh);
        my $image = <$fh>;
        close($fh);
    	$cache->set("$file-$x-$y-$caption-$ibg-$blowup-$pbg-$mtime", $image);	
    }
    
    my $fh = IO::Scalar->new(\$image); 	 

    my $contenttype = 'image/png'; 
    return Wx::Bitmap->new(Wx::Image->newStreamMIME($fh,  $contenttype)) 
}

sub wxColor2hex
{
    my $color = shift;
    my $red   = $color->Red();
    my $green = $color->Green();
    my $blue  = $color->Blue();
    return sprintf("#%0x%0x%0x", $red,$green,$blue);
}

sub ReadImageMagick
{
    my $file = shift;
    my ($x, $y, $caption, $bgcolor, $blowup, $parent_background) = @_;
    confess "MaxX and MaxY should be positive" if $x < 1 || $y < 1;
    return DrawCaption($x, $y, '?', $bgcolor, $parent_background) unless -r $file;

    $caption ||='';
    $blowup ||=0;
    $bgcolor = $parent_background unless defined $bgcolor;

    my $ibg = wxColor2hex($bgcolor) if (ref($bgcolor) eq 'Wx::Colour');
    my $pbg = wxColor2hex($parent_background) if (ref($parent_background) eq 'Wx::Colour');

    my $stat = stat($file);
    my $mtime = $stat->mtime();
    my $image = $cache->get("$file-$x-$y-$caption-$ibg-$blowup-$pbg-$mtime");
    if (!$image)
    {
    	my $radius = 10;
    	my $svg = <<SVG;
<svg width="$x" height="$y" viewBox="0 0 $x $y">
   <rect x="0" y="0" width="$x" height="$y" ry="$radius"
       style="stroke: none; fill: $ibg;"/>
</svg>
SVG
    	my $background=Image::Magick->new(magick => 'svg');
    	$background->Set('background' => $pbg);
    	$background->blobtoimage($svg);
        
    	my ($textheight, $textwidth) = (0,0);
    	if ($caption)
    	{
    	    my $pt = 20;
    	    do {
    		(undef, undef, undef, undef, $textwidth, $textheight, undef) =
    		    $background->QueryFontMetrics(text => $caption, font => 'Comic-Sans-MS', pointsize => $pt, gravity => 'South');
    		    $pt--;
    		} until ($textwidth < $x) && ($textheight < $y/5);
    	    $background->Annotate(text => $caption, font => 'Comic-Sans-MS', pointsize => $pt, gravity => 'South');
    	}
        
    	# Read the actual image
    	my $img = Image::Magick->new;
        
    	my $rc = $img->Read($file);
    	carp "Can't read $file: $rc" if $rc;
        # wmf files have a white background color by default
        # if we can't get the matte color for the image, we assume
        # that white can be used as the transparent color...
    	$img->Transparent(color => 'white') if (!$img->Get('matte') || $file =~ /wmf$/i);
    	my $w = $img->Get('width');
    	my $h = $img->Get('height');
    	my $ch = $textheight;
    	if (($w > $x) || ($h > ($y-$ch)))
    	{
    	    my ($newx, $newy) = ($w, $h);
    	    if ($w > $x)
    	    {
    		my $factor = $w/$x;
    		return wxNullBitmap if not $factor;
    		$newy = int($h/$factor);
    		($w,$h) = ($x, $newy);
    	    }
    	    if ($h > ($y-$ch))
    	    {
    		my $factor = $h/($y-$ch);
    		return wxNullBitmap if not $factor;
    		($w, $h) = (int($w/$factor),$y-$ch);
    	    }
    	    $img->Thumbnail(height => $h, width =>$w );
    	}
    	elsif ($blowup)
    	{
    	    # Do we really want to blow up images that are too small??
    	    my $factor = $w/$x;
    	    return wxNullBitmap if not $factor;
    	    my $newy = int($h/$factor);
    	    ($w,$h) = ($x, $newy);
    	    if ($h > ($y-$ch))
    	    {
    		my $factor = $h/($y-$ch);
    		return wxNullBitmap if not $factor;
    		($w, $h) = (int($w/$factor),$y-$ch);
    	    }
    	    $img->Resize(height => $h, width =>$w );
    	}
        
    	$img->Border(width  => int(($x - $img->Get('width'))/2) - $radius/2,
    		      height => int((($y-$textheight) - $img->Get('height'))/2) - $radius/2,
    		      fill   => $ibg);
    	
    	# Call the Composite method of the background image, with the logo image as an argument.
    	$background->Composite(image=>$img,compose=>'over', gravity => 'North');
    	$background->Set(quality=>100);
    	$background->Set(magick => 'png');
    	$image = $background->imagetoblob();
    	$cache->set("$file-$x-$y-$caption-$ibg-$blowup-$pbg-$mtime", $image);	
    	undef $background;
    	undef $img;
    }
    
    my $fh = IO::Scalar->new(\$image); 	 

    my $contenttype = 'image/png'; 
    return Wx::Bitmap->new(Wx::Image->newStreamMIME($fh,  $contenttype)) 
}

END
{
    undef $cache;
}

sub DrawCaption
{
    my ($x, $y, $caption, $background, $parent_background) = @_;

    confess "MaxX and MaxY should be positive" if $x < 1 || $y < 1;
    
    my $newbmp = Wx::Bitmap->new($x, $y);
    my $tmpdc = Wx::MemoryDC->new();
    $tmpdc->SelectObject($newbmp);

    my $bgbr = Wx::Brush->new($parent_background, wxSOLID);
    $tmpdc->SetBrush($bgbr); 
    $tmpdc->SetBackground($bgbr);
    $tmpdc->Clear();

    my $bg = $parent_background;
    if (defined $background)
    {
        if (ref($background)=~/ARRAY/)
        {
            $bg = Wx::Colour->new(@$background);
        }
        else
        {
            $bg = $background;
        }
        my $br = Wx::Brush->new($bg, wxSOLID);
        my $pen = Wx::Pen->new($bg, 1, wxSOLID);
        $tmpdc->SetBrush($br);
	$tmpdc->SetPen($pen);
	$tmpdc->DrawRoundedRectangle(1,1,$x-1,$y-1, 10);
    }

    my $pt = 72;
    my ($font, $w, $h);
    do
    {
	$font = Wx::Font->new(  $pt,                # font size
				wxSWISS,            # font family
				wxNORMAL,           # style
				wxNORMAL,           # weight
				0,                  
				'Comic Sans MS');   # face name
	($w, $h, undef, undef) = $tmpdc->GetTextExtent($caption, $font);
	$pt= $pt > 24 ? $pt - 4 : $pt-1;
    } until (($w<$x) && ($h<$y) || $pt < 5);
    $tmpdc->SetTextForeground(wxBLACK);
    $tmpdc->SetTextBackground($bg);
    $tmpdc->SetFont($font);
    $tmpdc->DrawText($caption, int(($x-$w)/2), int(($y-$h)/2));

    return $newbmp;
}

1;

__END__

=pod

=head1 NAME

AAC::Pvoice::Bitmap - Easily create resized bitmaps with options

=head1 SYNOPSIS

  use AAC::Pvoice::Bitmap;
  my $bitmap = AAC::Pvoice::Bitmap->new('image.jpg',        #image
                                        100,                #maxX
					100,                #maxY
					'This is my image', #caption
					wxWHITE,            #background
					1);                 #blowup?

=head1 DESCRIPTION

This module is a simpler interface to the Wx::Bitmap to do things with
images that I tend to do with almost every image I use in pVoice applications.

It's a subclass of Wx::Bitmap, so you can call any method that a Wx::Bitmap
can handle on the resulting AAC::Pvoice::Bitmap.

=head1 USAGE

=head2 new(image, maxX, maxY, caption, background, blowup, parentbackground)

This constructor returns a bitmap (useable as a normal Wx::Bitmap), that
has a size of maxX x maxY, the image drawn into it as large as possible.
If blowup has a true value, it will enlarge the image to try and match
the maxX and maxY. Any space not filled by the image will be the
specified background colour. A caption can be specified to draw under the
image.

If the image doesn't exist, it will draw a large questionmark and warn
the user.

=over 4

=item image

This is the path to the image you want to have.

=item maxX, maxY

These are the maximum X and Y size of the resulting image. If the original
image is larger, it will be resized (maintaining the aspect ratio) to
match these values as closely as possible. If the 'blowup' parameter is
set to a true value, it will also enlarge images that are smaller than
maxX and maxY to get the largest possible image within these maximum values.

=item caption

This is an optional caption below the image. The caption's font is Comic Sans MS
and will have a pointsize that will make the caption fit within the maxX
of the image. The resulting height of the caption is subtracted from the
maxY

=item background

This is the background of the image, specified as either a constant
(i.e. wxWHITE) or as an arrayref of RGB colours (like [128,150,201] ).

=item blowup

This boolean parameter determines whether or not images that are smaller
than maxX and maxY should be blown up to be as large as possible within
the given maxX and maxY.

=item parentbackground

This is the background of the parent of this bitmap, which is the colour to
be used outside of the round cornered background.

=back

=head1 BUGS

probably a lot, patches welcome!


=head1 AUTHOR

	Jouke Visser
	jouke@pvoice.org
	http://jouke.pvoice.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), Wx

=cut
