use v5.12;
use warnings;
use utf8;
use Wx;

package App::GUI::Harmonograph::Frame::Part::Board;
use base qw/Wx::Panel/;
my $TAU = 6.283185307;
my $PI  = 3.1415926535;
my $PHI = 1.618033988;
my $phi = 0.618033988;
my $e   = 2.718281828;
my $GAMMA = 1.7724538509055160;

use Graphics::Toolkit::Color;

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

sub set_sketch_flag { $_[0]->{'data'}{'sketch'} = 1 }


sub paint {
    my( $self, $dc, $width, $height ) = @_;
    my $background_color = Wx::Colour->new( 255, 255, 255 );
    $dc->SetBackground( Wx::Brush->new( $background_color, &Wx::wxBRUSHSTYLE_SOLID ) );     # $dc->SetBrush( $fgb );
    $dc->Clear();
    
    my $progress = $self->GetParent->{'progress'};

    my $start_color = Wx::Colour->new( $self->{'data'}{'start_color'}{'red'}, 
                                       $self->{'data'}{'start_color'}{'green'}, 
                                       $self->{'data'}{'start_color'}{'blue'} );

    my $thickness = $self->{'data'}{'line'}{'thickness'} == 0 ? 1 / 2 : $self->{'data'}{'line'}{'thickness'};
    $dc->SetPen( Wx::Pen->new( $start_color, $thickness, &Wx::wxPENSTYLE_SOLID) );

    my $cx = (defined $width) ? $width / 2 : $self->{'center'}{'x'};
    my $cy = (defined $height) ? $height / 2 : $self->{'center'}{'y'};
    my $raster_radius = (defined $height) ? (($width > $height ? $cy : $cx) - 25) : $self->{'hard_radius'};
    my $fx = $self->{'data'}{'x'}{'frequency'};
    my $fy = $self->{'data'}{'y'}{'frequency'};
    my $fz = $self->{'data'}{'z'}{'frequency'};
    my $fr = $self->{'data'}{'r'}{'frequency'};
    
    my $base_factor = { X => $fx, Y => $fy, Z => $fz, R => $fr, e => $e, 'π' => $PI, 'Φ' => $PHI, 'φ' => $phi, 'Γ' => $GAMMA };
    
    $fx *= ($base_factor->{ $self->{'data'}{'x'}{'freq_factor'} } // 1);
    $fy *= ($base_factor->{ $self->{'data'}{'y'}{'freq_factor'} } // 1);
    $fz *= ($base_factor->{ $self->{'data'}{'z'}{'freq_factor'} } // 1);
    $fr *= ($base_factor->{ $self->{'data'}{'r'}{'freq_factor'} } // 1);

    my $max_freq = abs $fx;
    $max_freq = abs $fy if $max_freq < abs $fy ;
    $max_freq = abs $fz if $max_freq < abs $fz;
    $max_freq = abs $fr if $max_freq < abs $fr;
    
    my $step_in_circle = exists $self->{'data'}{'sketch'} 
                       ? 300 * $max_freq
                       : $self->{'data'}{'line'}{'density'} * $self->{'data'}{'line'}{'density'} * $max_freq;
    my $t_iter =         exists $self->{'data'}{'sketch'} 
               ? 5 * $step_in_circle
               : $self->{'data'}{'line'}{'length'} * $step_in_circle;

    my $rx = $self->{'data'}{'x'}{'radius'} * $raster_radius;
    my $ry = $self->{'data'}{'y'}{'radius'} * $raster_radius;
    my $rz = $self->{'data'}{'z'}{'radius'} * $raster_radius;
    if ($self->{'data'}{'z'}{'on'}){
        $rx *= $self->{'data'}{'z'}{'radius'} / 2;
        $ry *= $self->{'data'}{'z'}{'radius'} / 2;
        $rz /=                                  2;
    }
    if ($self->{'data'}{'r'}{'on'}){
        $rx *= 2 * $self->{'data'}{'r'}{'radius'} / 3;
        $ry *= 2 * $self->{'data'}{'r'}{'radius'} / 3;
    }

    my $rxdamp  = (not $self->{'data'}{'x'}{'radius_damp'}) ? 0 : 
          ($self->{'data'}{'x'}{'radius_damp_type'} eq '*') ? 1 - ($self->{'data'}{'x'}{'radius_damp'} / 1000 / $step_in_circle) 
                                                            : $rx * $self->{'data'}{'x'}{'radius_damp'}/ 2000 / $step_in_circle;
    my $rydamp  = (not $self->{'data'}{'y'}{'radius_damp'}) ? 0 : 
          ($self->{'data'}{'y'}{'radius_damp_type'} eq '*') ? 1 - ($self->{'data'}{'y'}{'radius_damp'} / 1000 / $step_in_circle) 
                                                            : $ry * $self->{'data'}{'y'}{'radius_damp'}/ 2000 / $step_in_circle;
    my $rzdamp  = (not $self->{'data'}{'z'}{'radius_damp'}) ? 0 : 
          ($self->{'data'}{'z'}{'radius_damp_type'} eq '*') ? 1 - ($self->{'data'}{'z'}{'radius_damp'} / 1500 / $step_in_circle) 
                                                            : $rz * $self->{'data'}{'z'}{'radius_damp'}/ 3000 / $step_in_circle;
#    my $rrdamp  = (not $self->{'data'}{'r'}{'radius_damp'}) ? 0 : 
#         ($self->{'data'}{'r'}{'radius_damp_type'} eq '*') ? 1 - ($self->{'data'}{'r'}{'radius_damp'} / 1000 / $step_in_circle) 
#                                                           : $rr * $self->{'data'}{'r'}{'radius_damp'}/ 2000 / $step_in_circle;
    my $rxdacc  = (not $self->{'data'}{'x'}{'radius_damp_acc'}) ? 0 : 
          ($self->{'data'}{'x'}{'radius_damp_acc_type'} eq '*') ? 1 - ($self->{'data'}{'x'}{'radius_damp_acc'} / 1_000_000 / $step_in_circle) :
          ($self->{'data'}{'x'}{'radius_damp_acc_type'} eq '/') ? 1 + ($self->{'data'}{'x'}{'radius_damp_acc'} / 1_000_000 / $step_in_circle) 
                                                                : $rx * $self->{'data'}{'x'}{'radius_damp_acc'}/ 100_000_000 / $step_in_circle;
    my $rydacc  = (not $self->{'data'}{'y'}{'radius_damp_acc'}) ? 0 : 
          ($self->{'data'}{'y'}{'radius_damp_acc_type'} eq '*') ? 1 - ($self->{'data'}{'y'}{'radius_damp_acc'} / 1_000_000 / $step_in_circle) :
          ($self->{'data'}{'y'}{'radius_damp_acc_type'} eq '/') ? 1 + ($self->{'data'}{'y'}{'radius_damp_acc'} / 1_000_000 / $step_in_circle) 
                                                                : $ry * $self->{'data'}{'y'}{'radius_damp_acc'}/ 100_000_000 / $step_in_circle;
    my $rzdacc  = (not $self->{'data'}{'z'}{'radius_damp_acc'}) ? 0 : 
          ($self->{'data'}{'z'}{'radius_damp_acc_type'} eq '*') ? 1 - ($self->{'data'}{'z'}{'radius_damp_acc'} / 2_000_000 / $step_in_circle) :
          ($self->{'data'}{'z'}{'radius_damp_acc_type'} eq '/') ? 1 + ($self->{'data'}{'z'}{'radius_damp_acc'} / 2_000_000 / $step_in_circle) 
                                                                : $rz * $self->{'data'}{'z'}{'radius_damp_acc'}/ 200_000_000 / $step_in_circle;
#    my $rrdacc  = (not $self->{'data'}{'r'}{'radius_damp_acc'}) ? 0 : 
#          ($self->{'data'}{'r'}{'radius_damp_acc_type'} eq '*'
#        or $self->{'data'}{'x'}{'radius_damp_acc_type'} eq '/') ? 1 - ($self->{'data'}{'r'}{'radius_damp_acc'}/ 1000 / $step_in_circle) 
#                                                                : $rr * $self->{'data'}{'r'}{'radius_damp_acc'}/20000 / $step_in_circle;

    my $dtx =   $fx * $TAU / $step_in_circle;
    my $dty =   $fy * $TAU / $step_in_circle;
    my $dtz =   $fz * $TAU / $step_in_circle;
    my $dtr = - $fr * $TAU / $step_in_circle;
    $dtx =      0 unless $self->{'data'}{'x'}{'on'};
    $dty =      0 unless $self->{'data'}{'y'}{'on'};
    $dtz =      0 unless $self->{'data'}{'z'}{'on'};
    $dtr =      0 unless $self->{'data'}{'r'}{'on'};

    my $fxdamp  = (not $self->{'data'}{'x'}{'freq_damp'}) ? 0 : 
          ($self->{'data'}{'x'}{'freq_damp_type'} eq '*') ? 1 - ($self->{'data'}{'x'}{'freq_damp'}  / 40_000 / $step_in_circle) 
                                                          : $dtx * $self->{'data'}{'x'}{'freq_damp'}/ 40_000 / $step_in_circle;
    my $fydamp  = (not $self->{'data'}{'y'}{'freq_damp'}) ? 0 : 
          ($self->{'data'}{'y'}{'freq_damp_type'} eq '*') ? 1 - ($self->{'data'}{'y'}{'freq_damp'}  / 40_000 / $step_in_circle) 
                                                          : $dty * $self->{'data'}{'y'}{'freq_damp'}/ 40_000 / $step_in_circle;
    my $fzdamp  = (not $self->{'data'}{'z'}{'freq_damp'}) ? 0 : 
          ($self->{'data'}{'z'}{'freq_damp_type'} eq '*') ? 1 - ($self->{'data'}{'z'}{'freq_damp'}  / 20_000 / $step_in_circle) 
                                                          : $dtz * $self->{'data'}{'z'}{'freq_damp'}/ 20_000 / $step_in_circle;
    my $frdamp  = (not $self->{'data'}{'r'}{'freq_damp'}) ? 0 : 
          ($self->{'data'}{'r'}{'freq_damp_type'} eq '*') ? 1 - ($self->{'data'}{'r'}{'freq_damp'}  / 20_000 / $step_in_circle) 
                                                          : $dtr * $self->{'data'}{'r'}{'freq_damp'}/ 40_000 / $step_in_circle;

    my $tx = my $ty = my $tz = my $tr = 0;
    $tx += $TAU * $self->{'data'}{'x'}{'offset'} if $self->{'data'}{'x'}{'offset'};
    $ty += $TAU * $self->{'data'}{'y'}{'offset'} if $self->{'data'}{'y'}{'offset'};
    $tz += $TAU * $self->{'data'}{'z'}{'offset'} if $self->{'data'}{'z'}{'offset'};
    $tr += $TAU * $self->{'data'}{'r'}{'offset'} if $self->{'data'}{'r'}{'offset'};
    my ($x, $y);
    my $cflow = $self->{'data'}{'color_flow'};
    my $color_change_time;
    my @color;
    my $color_index = 0;
    my $startc = Graphics::Toolkit::Color->new( @{$self->{'data'}{'start_color'}}{'red', 'green', 'blue'} );
    my $endc = Graphics::Toolkit::Color->new( @{$self->{'data'}{'end_color'}}{'red', 'green', 'blue'} );
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
    } else { @color = ([$self->{'data'}{'start_color'}{'red'}, 
                        $self->{'data'}{'start_color'}{'green'}, 
                        $self->{'data'}{'start_color'}{'blue'}  ]);
    }
    $color_change_time = $step_in_circle * $cflow->{'stepsize'};
    
    $x = ($dtx ? $rx * cos $tx : 0);
    $y = ($dty ? $ry * sin $ty : 0);
    $x -= $rz * cos $tz if $dtz;
    $y -= $rz * sin $tz if $dtz;
    ($x, $y) = (($x * cos($rz) ) - ($y * sin($tr) ), ($x * sin($tr) ) + ($y * cos($tr) ) ) if $dtr;
    my ($x_old, $y_old) = ($x, $y);

    my $code = 'for (1 .. $t_iter){';
    $code .= ( $dtx ? '$x = $rx * cos $tx;' : '$x = 0;');
    $code .= ( $dty ? '$y = $ry * sin $ty;' : '$y = 0;');
    $code .= '$x -= $rz * cos $tz;' if $dtz;
    $code .= '$y -= $rz * sin $tz;' if $dtz;
    $code .= '($x, $y) = (($x * cos($tr) ) - ($y * sin($tr) ), ($x * sin($tr) ) + ($y * cos($tr) ) );' if $dtr;
    $code .= ($self->{'data'}{'line'}{'connect'} 
           ? '$dc->DrawLine( $cx + $x_old, $cy + $y_old, $cx + $x, $cy + $y);' 
           : '$dc->DrawPoint( $cx + $x, $cy + $y );');
    $code .= '$tx += $dtx;'         if $dtx;
    $code .= '$ty += $dty;'         if $dty;
    $code .= '$tz += $dtz;'         if $dtz;
    $code .= '$tr += $dtr;'         if $dtr;
    $code .= '$rx *= $rxdamp;'            if $rxdamp and $self->{'data'}{'x'}{'radius_damp_type'} eq '*';
    $code .= '$ry *= $rydamp;'            if $rydamp and $self->{'data'}{'y'}{'radius_damp_type'} eq '*';
    $code .= '$rz *= $rzdamp;'            if $rzdamp and $self->{'data'}{'z'}{'radius_damp_type'} eq '*';
    $code .= '$rx -= $rxdamp if $rx > 0;' if $rxdamp and $self->{'data'}{'x'}{'radius_damp_type'} eq '-';
    $code .= '$ry -= $rydamp if $ry > 0;' if $rydamp and $self->{'data'}{'y'}{'radius_damp_type'} eq '-';
    $code .= '$rz -= $rzdamp if $rz > 0;' if $rzdamp and $self->{'data'}{'z'}{'radius_damp_type'} eq '-';
    # $code .= '$dtr *= $rdamp;' if $rrdamp;
    $code .= '$rxdamp += $rxdacc;'  if $rxdacc and $rxdamp and $self->{'data'}{'x'}{'radius_damp_acc_type'} eq '+';
    $code .= '$rxdamp -= $rxdacc;'  if $rxdacc and $rxdamp and $self->{'data'}{'x'}{'radius_damp_acc_type'} eq '-';
    $code .= '$rxdamp *= $rxdacc;'  if $rxdacc and $rxdamp and $self->{'data'}{'x'}{'radius_damp_acc_type'} eq '*';
    $code .= '$rxdamp *= $rxdacc;'  if $rxdacc and $rxdamp and $self->{'data'}{'x'}{'radius_damp_acc_type'} eq '/';
    $code .= '$rydamp += $rydacc;'  if $rydacc and $rydamp and $self->{'data'}{'y'}{'radius_damp_acc_type'} eq '+';
    $code .= '$rydamp -= $rydacc;'  if $rydacc and $rydamp and $self->{'data'}{'y'}{'radius_damp_acc_type'} eq '-';
    $code .= '$rydamp *= $rydacc;'  if $rydacc and $rydamp and $self->{'data'}{'y'}{'radius_damp_acc_type'} eq '*';
    $code .= '$rydamp *= $rydacc;'  if $rydacc and $rydamp and $self->{'data'}{'y'}{'radius_damp_acc_type'} eq '/';
    $code .= '$rzdamp += $rzdacc;'  if $rzdacc and $rzdamp and $self->{'data'}{'z'}{'radius_damp_acc_type'} eq '+';
    $code .= '$rzdamp -= $rzdacc;'  if $rzdacc and $rzdamp and $self->{'data'}{'z'}{'radius_damp_acc_type'} eq '-';
    $code .= '$rzdamp *= $rzdacc;'  if $rzdacc and $rzdamp and $self->{'data'}{'z'}{'radius_damp_acc_type'} eq '*';
    $code .= '$rzdamp *= $rzdacc;'  if $rzdacc and $rzdamp and $self->{'data'}{'z'}{'radius_damp_acc_type'} eq '/';
#    $code .= '$rxdamp += $rxdacc;'  if $rrdacc and $rrdamp and $self->{'data'}{'r'}{'radius_damp_acc_type'} eq '+';
#    $code .= '$rxdamp -= $rxdacc;'  if $rrdacc and $rrdamp and $self->{'data'}{'r'}{'radius_damp_acc_type'} eq '-';
#    $code .= '$rxdamp *= $rxdacc;'  if $rrdacc and $rrdamp and $self->{'data'}{'r'}{'radius_damp_acc_type'} eq '*';
#    $code .= '$rxdamp *= $rxdacc;'  if $rrdacc and $rrdamp and $self->{'data'}{'r'}{'radius_damp_acc_type'} eq '/';
    $code .= '$dtx *= $fxdamp;'             if $fxdamp and $self->{'data'}{'x'}{'freq_damp_type'} eq '*';
    $code .= '$dty *= $fydamp;'             if $fydamp and $self->{'data'}{'y'}{'freq_damp_type'} eq '*';
    $code .= '$dtz *= $fzdamp;'             if $fzdamp and $self->{'data'}{'z'}{'freq_damp_type'} eq '*';
    $code .= '$dtr *= $frdamp;'             if $frdamp and $self->{'data'}{'r'}{'freq_damp_type'} eq '*';
    $code .= '$dtx -= $fxdamp if $dtx > 0;' if $fxdamp and $self->{'data'}{'x'}{'freq_damp_type'} eq '-';
    $code .= '$dty -= $fydamp if $dty > 0;' if $fydamp and $self->{'data'}{'y'}{'freq_damp_type'} eq '-';
    $code .= '$dtz -= $fzdamp if $dtz > 0;' if $fzdamp and $self->{'data'}{'z'}{'freq_damp_type'} eq '-';
    $code .= '$dtr += $frdamp if $dtr < 0;' if $frdamp and $self->{'data'}{'r'}{'freq_damp_type'} eq '-';

    $code .= '$dc->SetPen( Wx::Pen->new( Wx::Colour->new( @{$color[++$color_index]} ),'.
             ' $thickness, &Wx::wxPENSTYLE_SOLID)) unless $_ % $color_change_time;' if $cflow->{'type'} ne 'no' and @color;
    $code .= '$progress->add_percentage( $_ / $t_iter * 100, $color[$color_index] ) unless $_ % $step_in_circle;' unless defined $self->{'data'}{'sketch'};
    $code .= '($x_old, $y_old) = ($x, $y);' if $self->{'data'}{'line'}{'connect'};
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

# https://developer.mozilla.org/en-US/docs/Web/SVG/Element#shape_elements <polyline>
