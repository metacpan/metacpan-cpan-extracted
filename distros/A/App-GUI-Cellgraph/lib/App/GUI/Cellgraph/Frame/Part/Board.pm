use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Part::Board;
use base qw/Wx::Panel/;

use App::GUI::Cellgraph::Compute::Grid;
use Graphics::Toolkit::Color qw/color/;

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
    });
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
    $self->{'data'}{'sketch'} = 5;
    $self->Refresh;
}

sub set_settings {
    my( $self, $settings ) = @_;
    return 0 unless ref $settings eq 'HASH';
    $self->{'data'} = $settings;
    $self->{'data'}{'new'} = 1;
}

sub set_size {
    my( $self, $size ) = @_;
    return unless defined $size;
    $self->{'img_size'} = $size;
}

sub paint {
    my( $self, $dc, $width, $height ) = @_;

    $self->{'size'}{'cell'} = $self->{'data'}{'global'}{'cell_size'} // 3;
    $self->{'cells'}{'x'} = ($self->{'data'}{'global'}{'grid_type'} eq 'no')
                          ? int (  $width      /  $self->{'size'}{'cell'}      )
                          : int ( ($width - 1) / ($self->{'size'}{'cell'} + 1) );
    $self->{'cells'}{'y'} = ($self->{'data'}{'global'}{'grid_type'} eq 'no')
                          ? int (  $height      /  $self->{'size'}{'cell'}      )
                          : int ( ($height - 1) / ($self->{'size'}{'cell'} + 1) );
    $self->{'seed_cell'}  = int   $self->{'cells'}{'x'} / 2;
    my $cell_size = $self->{'size'}{'cell'};
    my $grid_d =  ($self->{'data'}{'global'}{'grid_type'} eq 'no')  ? $cell_size : $cell_size + 1;
    my $grid_max_x = $grid_d * $self->{'cells'}{'x'};
    my $grid_max_y = $grid_d * $self->{'cells'}{'y'};

    my $background_color = Wx::Colour->new( 255, 255, 255 );
    $dc->SetBackground( Wx::Brush->new( $background_color, &Wx::wxBRUSHSTYLE_SOLID ) );     # $dc->SetBrush( $fgb );
    $dc->Clear();
    my @color = map { Wx::Colour->new( $_->rgb ) } @{$self->{'data'}{'color'}{'objects'}};
    my @pen = map {Wx::Pen->new( $_, 1, &Wx::wxPENSTYLE_SOLID )} @color;
    my @brush = map { Wx::Brush->new( $_, &Wx::wxBRUSHSTYLE_SOLID ) } @color;
    $dc->SetPen( Wx::Pen->new( Wx::Colour->new( 170, 170, 170 ), 1, &Wx::wxPENSTYLE_SOLID ) );
    if ($self->{'data'}{'global'}{'grid_type'} eq 'lines'){
        $dc->DrawLine( 0,  0, $grid_max_x,    0);
        $dc->DrawLine( 0,  0,    0, $grid_max_y);
        $dc->DrawLine( $grid_d * $_,            0, $grid_d * $_, $grid_max_y ) for 1 .. $self->{'cells'}{'x'};
        $dc->DrawLine(            0, $grid_d * $_,  $grid_max_x, $grid_d * $_) for 1 .. $self->{'cells'}{'y'};
    }

    my $color = Wx::Colour->new( 0, 0, 0 );
    $dc->SetPen( Wx::Pen->new( $color, 1, &Wx::wxPENSTYLE_SOLID ) );
    $dc->SetBrush( Wx::Brush->new( $color, &Wx::wxBRUSHSTYLE_SOLID ) );
    my $grid = App::GUI::Cellgraph::Compute::Grid::now( [$self->{'cells'}{'x'}, $self->{'cells'}{'y'}], $self->{'data'} );

    my $sketch_length = exists $self->{'data'}{'sketch'} ? $self->{'data'}{'sketch'} : 0;
    if ($self->{'data'}{'global'}{'paint_direction'} eq 'inside_out') {
        my $mid = int($self->{'cells'}{'x'} / 2);
        if ($self->{'cells'}{'x'} % 2){
            for my $y (1 .. ($sketch_length ? $sketch_length : $mid)) {
                for my $x ($mid - $y .. $mid -1 + $y){
                    $dc->SetPen( $pen[$grid->[$y][$x]] );
                    $dc->SetBrush( $brush[$grid->[$y][$x]] );
                    my ($nx, $ny) = ($x, $mid + $y);
                    $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                    ($nx, $ny) = ($self->{'cells'}{'x'} - 1 - $x, $mid - $y);
                    $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                    ($nx, $ny) = ($mid - $y, $x);
                    $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                    ($nx, $ny) = ($mid + $y, $self->{'cells'}{'y'} - 1 - $x);
                    $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                }
                $dc->SetPen( $pen[ $grid->[0][$mid] ] );
                $dc->SetBrush( $brush[ $grid->[0][$mid] ] );

                $dc->DrawRectangle( 1 + ($mid * $grid_d), 1 + ($mid * $grid_d), $cell_size, $cell_size )
                    if $grid->[0][$mid];
            }
        } else {
            for my $y (0 .. ($sketch_length ? $sketch_length : (int($self->{'cells'}{'y'} / 2) + 1))) {
                last if $y >= $mid;
                for my $x ($mid - $y .. $mid + $y){
                    $dc->SetPen( $pen[$grid->[$y][$x]] );
                    $dc->SetBrush( $brush[$grid->[$y][$x]] );
                    my ($nx, $ny) = ($self->{'cells'}{'x'} - 1 - $x, $mid - 1 - $y);
                    $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                    ($nx, $ny) = ($x, $mid + $y);
                    $dc->DrawRectangle( 1 + ($x * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                    ($nx, $ny) = ($mid - 1 - $y, $x);
                    $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($x * $grid_d), $cell_size, $cell_size );
                    ($nx, $ny) = ($mid + $y, $self->{'cells'}{'x'} - 1 - $x);
                    $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                }
            }
        }
    } elsif ($self->{'data'}{'global'}{'paint_direction'} eq 'outside_in') {
        for my $y (0 .. ($sketch_length ? $sketch_length : (int($self->{'cells'}{'y'} / 2) + 1)) ) {
            last if $y >= $self->{'cells'}{'x'} - 2 - $y;
            for my $x ($y .. $self->{'cells'}{'x'} - 2 - $y){
                $dc->SetPen( $pen[$grid->[$y][$x]] );
                $dc->SetBrush( $brush[$grid->[$y][$x]] );
                my ($nx, $ny) = ($self->{'cells'}{'x'} - 1 - $x, $self->{'cells'}{'y'} - 1 - $y);
                $dc->DrawRectangle( 1 + ( $x * $grid_d), 1 + ( $y * $grid_d), $cell_size, $cell_size );
                $dc->DrawRectangle( 1 + ($nx * $grid_d), 1 + ($ny * $grid_d), $cell_size, $cell_size );
                $dc->DrawRectangle( 1 + ( $y * $grid_d), 1 + ($nx * $grid_d), $cell_size, $cell_size );
                $dc->DrawRectangle( 1 + ($ny * $grid_d), 1 + ( $x * $grid_d), $cell_size, $cell_size );
            }
        }
    } else {
        for my $y (0 .. ($sketch_length ? $sketch_length : $self->{'cells'}{'y'} - 1)) {
            for my $x (0 .. $self->{'cells'}{'x'} - 1){
                $dc->SetPen( $pen[$grid->[$y][$x]] );
                $dc->SetBrush( $brush[$grid->[$y][$x]] );
                $dc->DrawRectangle( 1 + ($x * $grid_d), 1 + ($y * $grid_d), $cell_size, $cell_size );
            }
        }
    }
    delete $self->{'data'}{'new'};
    delete $self->{'data'}{'sketch'};
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
