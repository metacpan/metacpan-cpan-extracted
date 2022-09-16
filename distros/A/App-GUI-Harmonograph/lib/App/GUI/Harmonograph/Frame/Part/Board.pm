use v5.12;
use warnings;
use Wx;

package App::GUI::Harmonograph::Frame::Part::Board;
use base qw/Wx::Panel/;
my $TAU = 6.283185307;
my $COPY_DC = 1;

sub new {
    my ( $class, $parent, $x, $y ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y] );
    $self->{'menu_size'} = 27;
    $self->{'size'}{'x'} = $x;
    $self->{'size'}{'y'} = $y;
    $self->{'center'}{'x'} = $x / 2;
    $self->{'center'}{'y'} = $y / 2;
    $self->{'hard_radius'} = ($x > $y ? $self->{'center'}{'y'} : $self->{'center'}{'x'}) - 25;
    $self->{'dc'} = Wx::MemoryDC->new( );
    $self->{'bmp'} = Wx::Bitmap->new( $self->{'size'}{'x'} + 10, $self->{'size'}{'y'} +10 + $self->{'menu_size'}, 24);
    $self->{'dc'}->SelectObject( $self->{'bmp'} );

    Wx::Event::EVT_PAINT( $self, sub {
        my( $self, $event ) = @_;
        return unless ref $self->{'data'} and ref $self->{'data'}{'x'};
        $self->{'x_pos'} = $self->GetPosition->x;
        $self->{'y_pos'} = $self->GetPosition->y;

        if (exists $self->{'data'}{'new'}) {
            $self->{'dc'}->Blit (0, 0, $self->{'size'}{'x'} + $self->{'x_pos'}, 
                                       $self->{'size'}{'y'} + $self->{'y_pos'} + $self->{'menu_size'}, 
                                       $self->paint( Wx::PaintDC->new( $self ) ), 0, 0);
        } else {
            Wx::PaintDC->new( $self )->Blit (0, 0, $self->{'size'}{'x'}, 
                                                   $self->{'size'}{'y'} + $self->{'menu_size'}, 
                                            $self->{'dc'}, 
                                                   $self->{'x_pos'} , $self->{'y_pos'} + $self->{'menu_size'} );
        }
        1;
    });
    
    # Blit (wxCoord xdest, wxCoord ydest, wxCoord width, wxCoord height, wxDC *source, wxCoord xsrc, wxCoord ysrc, wxRasterOperationMode logicalFunc=wxCOPY, bool useMask=false, wxCoord xsrcMask=wxDefaultCoord, wxCoord ysrcMask=wxDefaultCoord)
    
    return $self;
}

sub set_data {
    my( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    $self->{'data'} = $data;
    $self->{'data'}{'new'} = 1;
}

sub set_sketch_flag { $_[0]->{'data'}{'sketch'} = 1 }


sub paint {
    my( $self, $dc ) = @_;
    my $background_color = Wx::Colour->new( 255, 255, 255 );
    $dc->SetBackground( Wx::Brush->new( $background_color, &Wx::wxBRUSHSTYLE_SOLID ) );     # $dc->SetBrush( $fgb );
    $dc->Clear();
    
    my $progress = $self->GetParent->{'progress'};

    my $start_color = Wx::Colour->new( $self->{'data'}{'start_color'}{'red'}, 
                                       $self->{'data'}{'start_color'}{'green'}, 
                                       $self->{'data'}{'start_color'}{'blue'} );

    $dc->SetPen( Wx::Pen->new( $start_color, $self->{'data'}{'line'}{'thickness'}, &Wx::wxPENSTYLE_SOLID) );

    my $cx = $self->{'center'}{'x'};
    my $cy = $self->{'center'}{'y'};
    my $max_freq = abs $self->{'data'}{'x'}{'frequency'};

    $max_freq = abs $self->{'data'}{'y'}{'frequency'} if $max_freq < abs $self->{'data'}{'y'}{'frequency'};
    $max_freq = abs $self->{'data'}{'z'}{'frequency'} if $max_freq < abs $self->{'data'}{'z'}{'frequency'};
    $max_freq = abs $self->{'data'}{'r'}{'frequency'} if $max_freq < abs $self->{'data'}{'r'}{'frequency'};
    
    my $step_in_circle = exists $self->{'data'}{'sketch'} 
                       ? 300 * $max_freq
                       : $self->{'data'}{'line'}{'density'} * 10 * $max_freq;
    my $t_iter =         exists $self->{'data'}{'sketch'} 
               ? 5 * $step_in_circle
               : $self->{'data'}{'line'}{'length'} * $step_in_circle;

    my $xdamp  = $self->{'data'}{'x'}{'damp'} ? 1 - ($self->{'data'}{'x'}{'damp'}/10000/$step_in_circle) : 0;
    my $ydamp  = $self->{'data'}{'y'}{'damp'} ? 1 - ($self->{'data'}{'y'}{'damp'}/10000/$step_in_circle) : 0;
    my $zdamp  = $self->{'data'}{'z'}{'damp'} ? 1 - ($self->{'data'}{'z'}{'damp'}/10000/$step_in_circle) : 0;
    my $rdamp  = $self->{'data'}{'r'}{'damp'} ? 1 - ($self->{'data'}{'r'}{'damp'}/10000/$step_in_circle) : 0;

    my $rx = $self->{'data'}{'x'}{'radius'} * $self->{'hard_radius'};
    my $ry = $self->{'data'}{'y'}{'radius'} * $self->{'hard_radius'};
    my $rz = $self->{'data'}{'z'}{'radius'} * $self->{'hard_radius'};
    if ($self->{'data'}{'z'}{'on'}){
        $rx *= $self->{'data'}{'z'}{'radius'} / 2;
        $ry *= $self->{'data'}{'z'}{'radius'} / 2;
        $rz /=                                  2;
    }
    if ($self->{'data'}{'r'}{'on'}){
        $rx *= 2 * $self->{'data'}{'r'}{'radius'} / 3;
        $ry *= 2 * $self->{'data'}{'r'}{'radius'} / 3;
    }
    
    my $dtx =   $self->{'data'}{'x'}{'frequency'} * $TAU / $step_in_circle;
    my $dty =   $self->{'data'}{'y'}{'frequency'} * $TAU / $step_in_circle;
    my $dtz =   $self->{'data'}{'z'}{'frequency'} * $TAU / $step_in_circle;
    my $dtr = - $self->{'data'}{'r'}{'frequency'} * $TAU / $step_in_circle;
    $dtx =      0 unless $self->{'data'}{'x'}{'on'};
    $dty =      0 unless $self->{'data'}{'y'}{'on'};
    $dtz =      0 unless $self->{'data'}{'z'}{'on'};
    $dtr =      0 unless $self->{'data'}{'r'}{'on'};
    
    my $tx = my $ty = my $tz = my $tr = 0;
    $tx += $TAU * $self->{'data'}{'x'}{'offset'} if $self->{'data'}{'x'}{'offset'};
    $ty += $TAU * $self->{'data'}{'y'}{'offset'} if $self->{'data'}{'y'}{'offset'};
    $tz += $TAU * $self->{'data'}{'z'}{'offset'} if $self->{'data'}{'z'}{'offset'};
    $tr += $TAU * $self->{'data'}{'r'}{'offset'} if $self->{'data'}{'r'}{'offset'};
    my ($x, $y);
    my $cflow = $self->{'data'}{'color_flow'};
    my $color_change_time;
    my @color;
    my $color_index = 1;
    my $startc = App::GUI::Harmonograph::Color->new( @{$self->{'data'}{'start_color'}}{'red', 'green', 'blue'} );
    my $endc = App::GUI::Harmonograph::Color->new( @{$self->{'data'}{'end_color'}}{'red', 'green', 'blue'} );
    if ($cflow->{'type'} eq 'linear'){
        my $color_count = int ($self->{'data'}{'line'}{'length'} / $cflow->{'stepsize'});
        @color = map {[$_->rgb] } $startc->gradient_to( $endc, $color_count + 1, $cflow->{'dynamic'} );
    } elsif ($cflow->{'type'} eq 'alternate'){
        return unless exists $cflow->{'period'} and $cflow->{'period'} > 1;
        @color = map {[$_->rgb]} $startc->gradient_to( $endc, $cflow->{'period'}, $cflow->{'dynamic'} );
        my @tc = reverse @color;
        pop @tc;
        shift @tc;
        push @color, @tc;
        @tc = @color;
        my $color_circle_length = (2 * $cflow->{'period'} - 2) * $cflow->{'stepsize'};
        push @color, @tc for 0 .. int ($self->{'data'}{'line'}{'length'} / $color_circle_length);
    } elsif ($cflow->{'type'} eq 'circular'){
        return unless exists $cflow->{'period'} and $cflow->{'period'} > 1;
        @color = map {[$_->rgb]} $startc->complementary( $cflow->{'period'}, 
                                                         $endc->saturation - $startc->saturation,
                                                         $endc->lightness - $startc->lightness);
        my @tc = @color;
        push @color, @tc for 0 .. int ($self->{'data'}{'line'}{'length'} / $cflow->{'period'} / $cflow->{'stepsize'});
    }
    $color_change_time = $step_in_circle * $cflow->{'stepsize'};

    my $code = 'for (1 .. $t_iter){';
    $code .= ( $dtx ? '$x = $rx * cos $tx;' : '$x = 0;');
    $code .= ( $dty ? '$y = $ry * sin $ty;' : '$y = 0;');
    $code .= '$x -= $rz * cos $tz;' if $dtz;
    $code .= '$y -= $rz * sin $tz;' if $dtz;
    $code .= '($x, $y) = (($x * cos($rz) ) - ($y * sin($tr) ), ($x * sin($tr) ) + ($y * cos($tr) ) );' if $dtr;
    $code .= '$dc->DrawPoint( $cx + $x, $cy + $y );';
    $code .= '$tx += $dtx;'    if $dtx;
    $code .= '$ty += $dty;'    if $dty;
    $code .= '$tz += $dtz;'    if $dtz;
    $code .= '$tr += $dtr;'    if $dtr;
    $code .= '$rx *= $xdamp;'  if $xdamp;
    $code .= '$ry *= $ydamp;'  if $ydamp;
    $code .= '$rz *= $zdamp;'  if $zdamp;
    $code .= '$dtr *= $rdamp;' if $rdamp;
    $code .= '$progress->set_percentage( $_ / $t_iter * 100 ) unless $_ % $color_change_time;' unless defined $self->{'data'}{'sketch'};
    $code .= '$dc->SetPen( Wx::Pen->new( Wx::Colour->new( @{$color[$color_index++]} ),'.
             ' $self->{data}{line}{thickness}, &Wx::wxPENSTYLE_SOLID)) unless $_ % $color_change_time;' if $cflow->{'type'} ne 'no' and @color;
    $code .= '}';
    
    eval $code;
    die "bad iter code - $@ : $code" if $@;
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
    $width  //= $self->{'size'}{'x'};
    $height //= $self->{'size'}{'y'};
    my $dc = Wx::SVGFileDC->new( $file_name, $width, $height, 250 );  #  250 dpi
    $self->paint( $dc );
}

sub save_bmp_file {
    my( $self, $file_name, $file_end, $width, $height ) = @_;
    $width  //= $self->{'size'}{'x'};
    $height //= $self->{'size'}{'y'};
    my $bmp = Wx::Bitmap->new( $width, $height, 24); # bit depth
    my $dc = Wx::MemoryDC->new( );
    $dc->SelectObject( $bmp );
    $dc->Blit (0, 0, $self->{'size'}{'x'}, $self->{'size'}{'y'}, $self->{'dc'}, 10, 10 + $self->{'menu_size'});
    $dc->SelectObject( &Wx::wxNullBitmap );
    $bmp->SaveFile( $file_name, $file_end eq 'png' ? &Wx::wxBITMAP_TYPE_PNG : &Wx::wxBITMAP_TYPE_JPEG );
}

1;

# https://developer.mozilla.org/en-US/docs/Web/SVG/Element#shape_elements <polyline>
