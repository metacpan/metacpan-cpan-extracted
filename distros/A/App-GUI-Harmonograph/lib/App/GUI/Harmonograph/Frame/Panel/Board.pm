
# painting area on left side

package App::GUI::Harmonograph::Frame::Panel::Board;
use v5.12;
use warnings;
use utf8;
use Wx;
use base qw/Wx::Panel/;
use App::GUI::Harmonograph::Compute::Drawing;

sub new {
    my ( $class, $parent, $x, $y ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x+5, $y+5] );
    $self->{'precision'} = 4;
    $self->{'menu_size'} = 27;
    $self->{'size'}{'x'} = $x;
    $self->{'size'}{'y'} = $y;
    $self->{'center'}{'x'} = $x / 2;
    $self->{'center'}{'y'} = $y / 2;
    $self->{'hard_radius'} = ($x > $y ? $self->{'center'}{'y'} : $self->{'center'}{'x'});
    $self->{'dc'} = Wx::PaintDC->new( $self );

    Wx::Event::EVT_PAINT( $self, sub {
        my( $self, $event ) = @_;
        return unless exists $self->{'draw_args'};
        $self->{'x_pos'} = $self->GetPosition->x;
        $self->{'y_pos'} = $self->GetPosition->y;
        $self->{'dc'}->Blit (0, 0, $self->{'size'}{'x'} + $self->{'x_pos'},
                                   $self->{'size'}{'y'} + $self->{'y_pos'} + $self->{'menu_size'},
                                   $self->paint( Wx::PaintDC->new( $self ), $self->{'size'} ), 0, 0);
        #my $bmp = Wx::Bitmap->new( $self->{'size'}{'x'} , $self->{'size'}{'y'}, 24); # + 10
        #my $dc = Wx::MemoryDC->new( );
        # $dc->SelectObject( $bmp );
        #~ my $dc = Wx::PaintDC->new( $self );
        #~ $self->paint( $dc, $self->{'size'} );
        #~ #$self->{'dc'}->DrawBitmap($bmp, 0, 0, 1);
        #~ #$self->{'dc'} = Wx::PaintDC->new( $self );
        #~ #my $dc = Wx::MemoryDC->new( );
        #~ #$self->paint( $self->{'dc'}, $self->{'size'} );
        #~ $self->{'dc'}->Blit( 0 , 0, $self->{'size'}{'x'}, $self->{'size'}{'y'}, $dc, 0,0, &Wx::wxCOPY );
        #~ $self->{'dc'}->DestroyClippingRegion();
        #~ $dc->DestroyClippingRegion();
        # DrawBitmap()
        1;
    });

    return $self;
}

sub draw {
    my( $self, $settings, $progress_bar ) = @_;
    return unless ref $settings eq 'HASH' and ref $progress_bar;
    $self->{'draw_args'} = {settings => $settings, progress_bar => $progress_bar, redraw => 1 };
    $self->Refresh;
}
sub sketch {
    my( $self, $settings, $progress_bar ) = @_;
    return unless ref $settings eq 'HASH' and ref $progress_bar;
    $self->{'draw_args'} = {settings => $settings, progress_bar => $progress_bar, redraw => 1, sketch => 1};
    $self->Refresh;
}


sub paint {
    my( $self, $dc, $size) = @_;
    return unless ref $size eq 'HASH' and exists $self->{'draw_args'}{'settings'};
    $dc->SetBackground( Wx::Brush->new( Wx::Colour->new( 255, 255, 255 ), &Wx::wxBRUSHSTYLE_SOLID ) );
    $dc->Clear();

    my $Cx = (exists $size->{'width'})  ? ($size->{'width'} / 2)  : $self->{'center'}{'x'};
    my $Cy = (defined $size->{'height'}) ? ($size->{'height'} / 2) : $self->{'center'}{'y'};
    my $Cr = (defined $size->{'height'}) ? ($size->{'width'} > $size->{'height'} ? $Cx : $Cy)
                                         : $self->{'hard_radius'};
    my $board_size = $Cr;
    $Cr -= 15;

    #~ my $cr = App::GUI::Harmonograph::Compute::Drawing::draw( $dc );
    #~ $cr->($dc);

    my $code_ref = App::GUI::Harmonograph::Compute::Drawing::compile( $self->{'draw_args'}, $Cr );
    $code_ref->( $dc, $Cx, $Cy ) if ref $code_ref;
    delete $self->{'draw_args'};
    $dc;
}

sub save_file {
    my( $self, $file_name, $settings, $progress_bar, $width, $height ) = @_;
    $self->{'temp'} = {settings => $settings, progress_bar => $progress_bar};
    my $file_end = lc substr( $file_name, -3 );
    if ($file_end eq 'svg') { $self->save_svg_file( $file_name, $width, $height ) }
    elsif ($file_end eq 'png' or $file_end eq 'jpg') { $self->save_bmp_file( $file_name, $file_end, $width, $height ) }
    else { return "unknown file ending: '$file_end'" }
}

sub save_svg_file {
    my( $self, $file_name, $width, $height ) = @_;
    $width  //= $self->GetParent->{'config'}->get_value('image_size');
    $height //= $self->GetParent->{'config'}->get_value('image_size');
    $width  //= $self->{'size'}{'x'};
    $height //= $self->{'size'}{'y'};
    my $dc = Wx::SVGFileDC->new( $file_name, $width, $height, 250 );  #  250 dpi
    $self->paint( $dc, { width => $width, height => $height });

    #my $dc = Wx::SVGFileDC->new( $file_name, $width, $height, 250 )  #  250 dpi
                          #->Blit (0, 0, $width, $height, $memDC, 10, 10);
}

sub save_bmp_file {
    my( $self, $file_name, $file_end, $width, $height ) = @_;
    $width  //= $self->GetParent->{'config'}->get_value('image_size');
    $height //= $self->GetParent->{'config'}->get_value('image_size');
    $width  //= $self->{'size'}{'x'};
    $height //= $self->{'size'}{'y'};
    #~ my $bmp = Wx::Bitmap->new( $width, $height, 24); # bit depth
    #~ my $dc = Wx::MemoryDC->new( );
    #~ $self->paint( $dc, { width => $width, height => $height });
    #~ $dc->SelectObject( $bmp );
    #~ $dc->SelectObject( &Wx::wxNullBitmap );
    # $dc->SaveFile( $file_name, $file_end eq 'png' ? &Wx::wxBITMAP_TYPE_PNG : &Wx::wxBITMAP_TYPE_JPEG );
}

1;
