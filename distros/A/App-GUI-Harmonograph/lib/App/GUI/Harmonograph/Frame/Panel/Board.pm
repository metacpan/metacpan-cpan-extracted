
# painting area on left side

package App::GUI::Harmonograph::Frame::Panel::Board;
use v5.12;
use warnings;
use utf8;
use Wx;
use base qw/Wx::Panel/;
use Graphics::Toolkit::Color qw/color/; #
use App::GUI::Harmonograph::Compute::Drawing;

my $TAU = 6.283185307;

sub new {
    my ( $class, $parent, $x, $y ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y] );
    $self->{'precision'} = 4;
    $self->{'menu_size'} = 27;
    $self->{'size'}{'x'} = $x;
    $self->{'size'}{'y'} = $y;
    $self->{'center'}{'x'} = $x / 2;
    $self->{'center'}{'y'} = $y / 2;
    $self->{'hard_radius'} = ($x > $y ? $self->{'center'}{'y'} : $self->{'center'}{'x'});
    $self->{'bmp'} = Wx::Bitmap->new( $self->{'size'}{'x'} + 10, $self->{'size'}{'y'} +10 + $self->{'menu_size'}, 24);
    $self->{'dc'} = Wx::MemoryDC->new( );
    $self->{'dc'}->SelectObject( $self->{'bmp'} );

    Wx::Event::EVT_PAINT( $self, sub {
        my( $self, $event ) = @_;
        return unless ref $self->{'settings'} and ref $self->{'settings'}{'x'};
        $self->{'x_pos'} = $self->GetPosition->x;
        $self->{'y_pos'} = $self->GetPosition->y;

        if (exists $self->{'flag'}{'new'}) {
            $self->{'dc'}->Blit (0, 0, $self->{'size'}{'x'} + $self->{'x_pos'},
                                       $self->{'size'}{'y'} + $self->{'y_pos'} + $self->{'menu_size'},
                                       $self->paint( Wx::PaintDC->new( $self ), $self->{'size'}{'x'}, $self->{'size'}{'y'} ), 0, 0);
        } else {
            Wx::PaintDC->new( $self )->Blit (0, 0, $self->{'size'}{'x'},
                                                   $self->{'size'}{'y'} + $self->{'menu_size'},
                                                   $self->{'dc'},
                                                   $self->{'x_pos'} , $self->{'y_pos'} + $self->{'menu_size'} );
        }
        1;
    }); # Blit (xdest, ydest, width, height, DC *src, xsrc, ysrc, wxRasterOperationMode logicalFunc=wxCOPY, bool useMask=false)
    return $self;
}

sub draw {
    my( $self, $settings ) = @_;
    return unless $self->set_settings( $settings );
    $self->Refresh;
}
sub sketch {
    my( $self, $settings ) = @_;
    return unless $self->set_settings( $settings );
    $self->{'flag'}{'sketch'} = 1;
    $self->Refresh;
}
sub set_settings {
    my( $self, $settings ) = @_;
    return unless ref $settings eq 'HASH';
    $self->GetParent->{'progress_bar'}->reset;
    $self->{'settings'} = $settings;
    $self->{'flag'}{'new'} = 1;
}


sub paint {
    my( $self, $dc, $width, $height ) = @_;
    my $progress_bar = $self->GetParent->{'progress_bar'};
    $dc->SetBackground( Wx::Brush->new( Wx::Colour->new( 255, 255, 255 ), &Wx::wxBRUSHSTYLE_SOLID ) );
    $dc->Clear();

    my $Cx = (defined $width)  ? ($width / 2)  : $self->{'center'}{'x'};
    my $Cy = (defined $height) ? ($height / 2) : $self->{'center'}{'y'};
    my $Cr = (defined $height) ? ($width > $height ? $Cx : $Cy) : $self->{'hard_radius'};
    my $board_size = $Cr;
    $Cr -= 15;

    my $code_ref = App::GUI::Harmonograph::Compute::Drawing::compile(
        $self->{'settings'}, $progress_bar, $Cr, $board_size, $self->{'flag'}{'sketch'}
    );
    $code_ref->( $dc, $Cx, $Cy ) if ref $code_ref;

    delete $self->{'flag'};
    $dc;
}

sub save_file {
    my( $self, $file_name, $width, $height ) = @_;
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
    $self->paint( $dc, $width, $height );
}

sub save_bmp_file {
    my( $self, $file_name, $file_end, $width, $height ) = @_;
    $width  //= $self->GetParent->{'config'}->get_value('image_size');
    $height //= $self->GetParent->{'config'}->get_value('image_size');
    $width  //= $self->{'size'}{'x'};
    $height //= $self->{'size'}{'y'};
    my $bmp = Wx::Bitmap->new( $width, $height, 24); # bit depth
    my $dc = Wx::MemoryDC->new( );
    $dc->SelectObject( $bmp );
    $self->paint( $dc, $width, $height);
    # $dc->Blit (0, 0, $width, $height, $self->{'dc'}, 10, 10 + $self->{'menu_size'});
    $dc->SelectObject( &Wx::wxNullBitmap );
    $bmp->SaveFile( $file_name, $file_end eq 'png' ? &Wx::wxBITMAP_TYPE_PNG : &Wx::wxBITMAP_TYPE_JPEG );
}

1;
