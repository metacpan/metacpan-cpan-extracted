use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Part::Board;
use base qw/Wx::Panel/;
my $TAU = 6.283185307;

# use Graphics::Toolkit::Color;
use App::GUI::Cellgraph::Grid;

sub new {
    my ( $class, $parent, $x, $y ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y] );
    $self->{'img_size'} = 700;
    $self->{'menu_size'} = 27;
    $self->{'size'}{'x'} = $x;
    $self->{'size'}{'y'} = $y;
    $self->{'dc'} = Wx::MemoryDC->new( );
    $self->{'bmp'} = Wx::Bitmap->new( $self->{'size'}{'x'} + 10, $self->{'size'}{'y'} +10 + $self->{'menu_size'}, 24);
    $self->{'dc'}->SelectObject( $self->{'bmp'} );

    Wx::Event::EVT_PAINT( $self, sub {
        my( $self, $event ) = @_;
        return unless ref $self->{'data'};
        $self->{'x_pos'} = $self->GetPosition->x;
        $self->{'y_pos'} = $self->GetPosition->y;

        if (exists $self->{'data'}{'new'}) {
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

sub set_data {
    my( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    $self->{'data'} = $data;
    $self->{'data'}{'new'} = 1;
}

sub set_size {
    my( $self, $size ) = @_;
    return unless defined $size;
    $self->{'img_size'} = $size;
}

sub paint {
    my( $self, $dc, $width, $height ) = @_;
    
    $self->{'size'}{'cell'} = $self->{'data'}{'start'}{'cell_size'} // 3;
    $self->{'cells'}{'x'} = ($self->{'data'}{'start'}{'grid'} eq 'no') 
                          ? int (  $width      /  $self->{'size'}{'cell'}      )
                          : int ( ($width - 1) / ($self->{'size'}{'cell'} + 1) );
    $self->{'cells'}{'y'} = ($self->{'data'}{'start'}{'grid'} eq 'no') 
                          ? int (  $height      /  $self->{'size'}{'cell'}      )
                          : int ( ($height - 1) / ($self->{'size'}{'cell'} + 1) );
    $self->{'seed_cell'}  = int   $self->{'cells'}{'x'} / 2;
    my $cell_size = $self->{'size'}{'cell'};
    my $grid_d =  ($self->{'data'}{'start'}{'grid'} eq 'no')  ? $cell_size : $cell_size + 1;
    my $grid_max_x = $grid_d * $self->{'cells'}{'x'};
    my $grid_max_y = $grid_d * $self->{'cells'}{'y'};
    
    my $background_color = Wx::Colour->new( 255, 255, 255 );
    $dc->SetBackground( Wx::Brush->new( $background_color, &Wx::wxBRUSHSTYLE_SOLID ) );     # $dc->SetBrush( $fgb );
    $dc->Clear();
    $dc->SetPen( Wx::Pen->new( Wx::Colour->new( 170, 170, 170 ), 1, &Wx::wxPENSTYLE_SOLID ) );
    if ($self->{'data'}{'start'}{'grid'} eq 'lines'){
        $dc->DrawLine( 0,  0, $grid_max_x,    0);
        $dc->DrawLine( 0,  0,    0, $grid_max_y);
        $dc->DrawLine( $grid_d * $_,            0, $grid_d * $_, $grid_max_y ) for 1 .. $self->{'cells'}{'x'};
        $dc->DrawLine(            0, $grid_d * $_,  $grid_max_x, $grid_d * $_) for 1 .. $self->{'cells'}{'y'};
    }
 
    my $color = Wx::Colour->new( 0, 0, 0 );
    $dc->SetPen( Wx::Pen->new( $color, 1, &Wx::wxPENSTYLE_SOLID ) );
    $dc->SetBrush( Wx::Brush->new( $color, &Wx::wxBRUSHSTYLE_SOLID ) );
    my $grid = App::GUI::Cellgraph::Grid::get( [$self->{'cells'}{'x'}, $self->{'cells'}{'y'}],
                                                $self->{'data'}{'rules'}, $self->{'data'}{'start'} );
 
    for my $x (0 .. $self->{'cells'}{'x'} - 1){
        for my $y (0 .. $self->{'cells'}{'y'} - 1) {
            $dc->DrawRectangle( 1 + ($x * $grid_d), 1 + ($y * $grid_d), $cell_size, $cell_size )
                if $grid->[$y][$self->{'cells'}{'x'} + $x];
        }
    }
    delete $self->{'data'}{'new'};
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
    $width  //= $self->{'img_size'};
    $height //= $self->{'img_size'};
    $width  //= $self->{'size'}{'x'};
    $height //= $self->{'size'}{'y'};
    my $dc = Wx::SVGFileDC->new( $file_name, $width, $height, 250 );  #  250 dpi
    $self->paint( $dc, $width, $height );
}

sub save_bmp_file {
    my( $self, $file_name, $file_end, $width, $height ) = @_;
    $width  //= $self->{'img_size'};
    $height //= $self->{'img_size'};
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
