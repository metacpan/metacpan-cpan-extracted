use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Frame::Panel::Board;
use base qw/Wx::Panel/;
use Benchmark;

use App::GUI::Cellgraph::Compute::Grid;
use Graphics::Toolkit::Color qw/color/;

sub new {
    my ( $class, $parent, $size ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$size, $size] );
    $self->{'img_size'} = $size;
    $self->{'menu_size'} = 27;
    $self->{'size'}{'x'} = $size;
    $self->{'size'}{'y'} = $size;
    $self->{'dc'} = Wx::MemoryDC->new( );
    $self->{'bmp'} = Wx::Bitmap->new( $self->{'size'}{'x'} + 10, $self->{'size'}{'y'} +10 + $self->{'menu_size'}, 24);
    $self->{'dc'}->SelectObject( $self->{'bmp'} );

    Wx::Event::EVT_PAINT( $self, sub {
        my( $self, $event ) = @_;
        return unless ref $self->{'state'};
        $self->{'x_pos'} = $self->GetPosition->x;
        $self->{'y_pos'} = $self->GetPosition->y;

        if (exists $self->{'flag'}{'state_changed'}) {
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
    my( $self, $state ) = @_;
    delete $self->{'flag'}; # ugly workaround
    return unless $self->set_state( $state );
    $self->{'flag'}{'draw'} = 1;
    $self->Refresh;
}

sub sketch {
    my( $self, $state ) = @_;
    delete $self->{'flag'}; # ugly workaround
    return unless $self->set_state( $state );
    $self->{'flag'}{'sketch'} = 5;
    $self->Refresh;
}

sub set_state {
    my( $self, $state ) = @_;
    return 0 unless ref $state eq 'HASH';
    $self->{'state'} = $state;
    $self->{'flag'}{'state_changed'} = 1;
}

sub set_size {
    my( $self, $size ) = @_;
    return unless defined $size;
    $self->{'img_size'} = $size;
}

sub paint {
    my( $self, $dc, $width, $height ) = @_;

    $self->{'size'}{'cell'} = $self->{'state'}{'global'}{'cell_size'} // 3;
    $self->{'cells'}{'x'} = ($self->{'state'}{'global'}{'grid_type'} eq 'no')
                          ? int (  $width      /  $self->{'size'}{'cell'}      )
                          : int ( ($width - 1) / ($self->{'size'}{'cell'} + 1) );
    $self->{'cells'}{'y'} = ($self->{'state'}{'global'}{'grid_type'} eq 'no')
                          ? int (  $height      /  $self->{'size'}{'cell'}      )
                          : int ( ($height - 1) / ($self->{'size'}{'cell'} + 1) );

    my $cell_size = $self->{'size'}{'cell'};
    my $grid_d =  ($self->{'state'}{'global'}{'grid_type'} eq 'no')  ? $cell_size : $cell_size + 1;
    my $grid_max_x = $grid_d * $self->{'cells'}{'x'};
    my $grid_max_y = $grid_d * $self->{'cells'}{'y'};
    my $sketch_length = exists $self->{'flag'}{'sketch'} ? $self->{'flag'}{'sketch'} : 0;

        $dc->Clear();
        $dc->SetPen( Wx::Pen->new( Wx::Colour->new( 170, 170, 170 ), 1, &Wx::wxPENSTYLE_SOLID ) );
        #$dc->SetBackground( Wx::Brush->new( Wx::Colour->new( 255, 255, 255 ), &Wx::wxBRUSHSTYLE_SOLID ) );
        if ($self->{'state'}{'global'}{'grid_type'} eq 'lines'){
            $dc->DrawLine( 0,  0, $grid_max_x,    0);
            $dc->DrawLine( 0,  0,    0, $grid_max_y);
            $dc->DrawLine( $grid_d * $_,            0, $grid_d * $_, $grid_max_y ) for 1 .. $self->{'cells'}{'x'};
            $dc->DrawLine(            0, $grid_d * $_,  $grid_max_x, $grid_d * $_) for 1 .. $self->{'cells'}{'y'};
        }

    my @color = map { Wx::Colour->new( $_->rgb ) } @{$self->{'state'}{'color'}{'objects'}};
    my @pen   = map {Wx::Pen->new( $_, 1, &Wx::wxPENSTYLE_SOLID )} @color;
    my @brush = map { Wx::Brush->new( $_, &Wx::wxBRUSHSTYLE_SOLID ) } @color;
    my $grid  = App::GUI::Cellgraph::Compute::Grid::create( $self->{'state'}, $self->{'cells'}{'x'}, $sketch_length );
    my $rows  = $sketch_length ? ($sketch_length - 1) : ($self->{'cells'}{'x'} - 1);
    my $cell_size_iterator = [0 .. $self->{'state'}{'global'}{'cell_size'}-1];
    my $cl = $cell_size - 1;
    my $y_cursor = 1;
#my $t1 = Benchmark->new;
    if ($self->{'state'}{'global'}{'fill_cells'}){
        for my $y (0 .. $rows) {
            my $x_cursor = 1;
            for my $x (0 .. $self->{'cells'}{'x'}-1) {
                $dc->SetPen( $pen[$grid->[$y][$x] // 0] );
                $dc->DrawLine( $x_cursor, $y_cursor+$_, $x_cursor + $cl, $y_cursor+$_) for @$cell_size_iterator;
                #$dc->SetBrush( $brush[$grid->[$y][$x]] );
                #$dc->DrawRectangle( $x_cursor, $y_cursor, $cell_size, $cell_size );
                $x_cursor += $grid_d;
            }
            $y_cursor += $grid_d;
        }
    } else {
        for my $y (0 .. $rows) {
            my $x_cursor = 1;
            for my $x (0 .. $self->{'cells'}{'x'}-1) {
                $dc->SetPen( $pen[$grid->[$y][$x]] );
                $dc->DrawLine( $x_cursor, $y_cursor, $x_cursor + $cl, $y_cursor);
                $dc->DrawLine( $x_cursor, $y_cursor + $cl, $x_cursor + $cl, $y_cursor + $cl);
                # $dc->DrawLine( $x_cursor, $y_cursor, $x_cursor, $y_cursor + $cl);
                # $dc->DrawLine( $x_cursor + $cl, $y_cursor, $x_cursor + $cl, $y_cursor + $cl);
                $x_cursor += $grid_d;
            }
            $y_cursor += $grid_d;
        }
    }
#say "paint took:",timestr( timediff(Benchmark->new, $t1) );
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
    #$dc->Blit (0, 0, $width, $height, $self->{'dc'}, 10, 10 + $self->{'menu_size'});
    $dc->SelectObject( &Wx::wxNullBitmap );
    $bmp->SaveFile( $file_name, $file_end eq 'png' ? &Wx::wxBITMAP_TYPE_PNG : &Wx::wxBITMAP_TYPE_JPEG );
}

1;
