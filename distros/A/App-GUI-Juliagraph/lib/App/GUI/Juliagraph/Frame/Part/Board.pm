use v5.12;
use warnings;
use Wx;

package App::GUI::Juliagraph::Frame::Part::Board;
use base qw/Wx::Panel/;

use Graphics::Toolkit::Color qw/color/;
#use Benchmark;

use constant SKETCH_FACTOR => 4;


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
        return unless ref $self->{'data'};
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
    # Wx::Event::EVT_LEFT_DOWN( $self->{'board'}, sub {});

    return $self;
}

sub draw {
    my( $self, $settings ) = @_;
    return unless $self->set_settings( $settings );
    $self->{'flag'}{'draw'} = 1;
    $self->Refresh;
}

sub sketch {
    my( $self, $settings ) = @_;
    return unless $self->set_settings( $settings );
    $self->{'flag'}{'sketch'} = 1;
    $self->Refresh;
}

sub set_settings {
    my( $self, $data ) = @_;
    return unless ref $data eq 'HASH';
    $self->GetParent->{'progress'}->reset;
    $self->{'data'} = $data;
    $self->{'flag'}{'new'} = 1;
}


sub paint {
    my( $self, $dc, $width, $height ) = @_;
    #my $t0 = Benchmark->new();
    my %factor = ();
    my $max_exp;
    for my $mnr (1 .. 4){
        my $settings = $self->{'data'}{'monomial_'.$mnr};
        next unless $settings->{'active'};
        my $f = $settings->{'use_factor'} ? [$settings->{'factor_r'}, $settings->{'factor_i'}] : [1,1];
        if (exists $factor{$settings->{'exponent'}}) {
            $factor{ $settings->{'exponent'} }[0] *= $f->[0];
            $factor{ $settings->{'exponent'} }[1] *= $f->[1];
        } else { $factor{ $settings->{'exponent'} } = $f }
        $max_exp = $settings->{'exponent'} unless defined $max_exp;
        $max_exp = $settings->{'exponent'} if $max_exp < $settings->{'exponent'};
    }
    $max_exp = 0 unless defined $max_exp;

    my $zoom_size = 4 * (10** (-$self->{'data'}{'constraints'}{'zoom'}));
    my $stop = $self->{'data'}{'constraints'}{'stop_value'};
    my $x_delta = $zoom_size;
    my $x_delta_step = $x_delta / $self->{'size'}{'x'};
    my $x_min = $self->{'data'}{'constraints'}{'pos_x'} - ($x_delta / 2);
    my $y_delta = $zoom_size;
    my $y_delta_step = $y_delta / $self->{'size'}{'y'};
    my $y_min = $self->{'data'}{'constraints'}{'pos_y'} - ($y_delta / 2);
    my $const_a = ($self->{'data'}{'constraints'}{'constant'} eq 'constant') ? $self->{'data'}{'constraints'}{'const_a'} : 0;
    my $const_b = ($self->{'data'}{'constraints'}{'constant'} eq 'constant') ? $self->{'data'}{'constraints'}{'const_b'} : 0;
    $const_a *= $factor{0}[0] if exists $factor{0} and $factor{0}[0];
    $const_b *= $factor{0}[1] if exists $factor{0} and $factor{0}[1];
    my $position = $self->{'data'}{'constraints'}{'position'};
    $position = substr($position, 7) if substr($position, 0, 7) eq 'degree ';
    if ($position =~ /\d/){
        $max_exp = $position if $max_exp < $position;
    }

    my $metric = { '|var|' => '($x*$x) + ($y*$y)', '|x|' => 'abs($x)',         '|y|' => 'abs($y)',
                   '|x+y|' => 'abs($x+$y)',    '|x|+|y|' => 'abs($x)+abs($y)', 'x+y' => '$x+$y',
                    'x*y'  => '$x*$y',           '|x*y|' => 'abs($x*$y)',
                     'x-y' => '$x-$y',             'y-x' => '$y-$x',
    };

    my $background_color = Wx::Colour->new( 255, 255, 255 );
    $dc->SetBackground( Wx::Brush->new( $background_color, &Wx::wxBRUSHSTYLE_SOLID ) );
    $dc->Clear();

    my $progress = $self->GetParent->{'progress'};
    my $colors = $self->{'data'}{'mapping'}{'select'} * ($self->{'data'}{'mapping'}{'gradient'}+1)
               * $self->{'data'}{'mapping'}{'repeat'} * $self->{'data'}{'mapping'}{'group'};
    my @color = ();
    if ($self->{'data'}{'mapping'}{'color'}){
        $self->{'data'}{'color'}{ $self->{'data'}{'mapping'}{'select'} } = $self->{'data'}{'color'}{ 8 };
        for my $i (0 .. $self->{'data'}{'mapping'}{'select'} - 1) {
            my @gradient = map {[$_->values]}
                           color($self->{'data'}{'color'}{$i})->gradient( to => $self->{'data'}{'color'}{$i+1},
                                                                          steps => $self->{'data'}{'mapping'}{'gradient'}+2,
                                                                          dynamic => $self->{'data'}{'mapping'}{'dynamics'},
                                                                        );
            pop @gradient;
            @color = (@color, @gradient);
        }
    } else {
            @color = map {[$_->values]} color('white')->gradient( to => 'black',
                                                               steps => $self->{'data'}{'mapping'}{'select'} * ($self->{'data'}{'mapping'}{'gradient'}+2),
                                                             dynamic => $self->{'data'}{'mapping'}{'dynamics'},
                                                                );
    }
    if ($self->{'data'}{'mapping'}{'group'} > 1){
        my @temp = @color;
        @color = ();
        for my $color (@temp){
            push @color, $color for 1 .. $self->{'data'}{'mapping'}{'group'};
        }
    }
    if ($self->{'data'}{'mapping'}{'repeat'} > 1){
        my @temp = @color;
        @color = (@color, @temp) for 2 .. $self->{'data'}{'mapping'}{'repeat'};
    }
    if ($self->{'flag'}{'draw'}){
        $progress->add_percentage( $_ / $#color * 100, $color[$_] ) for 0 .. $#color;
        $progress->full;
    }
    $color[$_] = [0,0,0] for $colors .. $self->{'data'}{'constraints'}{'stop_value'}; # background color


    if ($self->{'flag'}{'sketch'}){
        $x_delta_step *= SKETCH_FACTOR;
        $y_delta_step *= SKETCH_FACTOR;
        $colors = 20 if $colors > 20;
        $stop = 100 if $stop > 100;
    }

    my $img = Wx::Image->new($self->{'size'}{'x'},$self->{'size'}{'y'});
    my ($x_const, $y_const, $x, $y, $x_old, $y_old, $x_pot, $y_pot);

    my $code = 'my ($x_num, $x_pix) = ($x_min, 0);'."\n";
    $code .= $self->{'flag'}{'sketch'}
           ? 'for (0 .. $self->{size}{x} / SKETCH_FACTOR){'."\n"
           : 'for (0 .. $self->{size}{x}){'."\n";
    $code .= '  my ($y_num, $y_pix) = ($y_min, $self->{size}{y});'."\n";
    $code .= $self->{'flag'}{'sketch'}
           ? '  for (0 .. $self->{size}{y} / SKETCH_FACTOR){'."\n"
           : '  for (0 .. $self->{size}{y}){'."\n";

    my $x_start_value = ($self->{'data'}{'constraints'}{'constant'} eq 'start value') ? $self->{'data'}{'constraints'}{'const_a'} : 0;
    my $y_start_value = ($self->{'data'}{'constraints'}{'constant'} eq 'start value') ? $self->{'data'}{'constraints'}{'const_b'} : 0;

    if ($position eq 'start value'){
        $x_start_value = $x_start_value ? $x_start_value . ' + $x_num' : '$x_num';
        $y_start_value = $y_start_value ? $y_start_value . ' + $y_num' : '$y_num';
    }

    $code .= '    $x = '.$x_start_value.';'."\n";
    $code .= '    $y = '.$y_start_value.';'."\n";
    $code .= '    for my $i (0 .. $colors){'."\n";
    $code .= '      $x_pot = $x_old = $x;'."\n";
    $code .= '      $y_pot = $y_old = $y;'."\n";
    $code .= '      $x = '.(($position eq 'constant') ? $const_a.'+ $x_num' : $const_a).';'."\n";
    $code .= '      $y = '.(($position eq 'constant') ? $const_b.'+ $y_num' : $const_b).';'."\n";

    for my $exponent (2 .. $max_exp){
        $code .= '      ($x_pot, $y_pot) = (($x_pot * $x_old) - ($y_pot * $y_old), ($x_pot * $y_old) + ($x_old * $y_pot));'."\n";
        my $x_factor = (exists $factor{$exponent} and $factor{$exponent}[0]) ? ' * '.$factor{$exponent}[0] : '';
        my $y_factor = (exists $factor{$exponent} and $factor{$exponent}[1]) ? ' * '.$factor{$exponent}[1] : '';
        if ($position eq $exponent){
            $x_factor .= ' * $x_num';
            $y_factor .= ' * $y_num';
        }
        $code .= '      $x += $x_pot '.$x_factor.';'."\n" if $x_factor;
        $code .= '      $y += $y_pot '.$y_factor.';'."\n" if $y_factor;
    }
    my $x_linear = (exists $factor{1} and $factor{1}[0]) ? ' * '.$factor{1}[0] : '';
    my $y_linear = (exists $factor{1} and $factor{1}[1]) ? ' * '.$factor{1}[1] : '';
    if ($position eq 1){
        $x_linear .= ' * $x_num';
        $y_linear .= ' * $y_num';
    }
    $code .= '      $x += $x_old '.$x_linear.';'."\n" if $x_linear;
    $code .= '      $y += $y_old '.$y_linear.';'."\n" if $y_linear;
    $code .= '      if ('.$metric->{$self->{'data'}{'constraints'}{'stop_metric'}}.' > $stop){'."\n";
    $code .= '        $img->SetRGB( $x_pix,   $y_pix,   @{$color[$i]});'."\n";
    $code .= '        $img->SetRGB( $x_pix,   $y_pix+1, @{$color[$i]});'."\n".
             '        $img->SetRGB( $x_pix+1, $y_pix,   @{$color[$i]});'."\n".
             '        $img->SetRGB( $x_pix+1, $y_pix+1, @{$color[$i]});'."\n".
             '        $img->SetRGB( $x_pix+1, $y_pix+2, @{$color[$i]});'."\n".
             '        $img->SetRGB( $x_pix+2, $y_pix+1, @{$color[$i]});'."\n" if $self->{'flag'}{'sketch'};
    $code .= '        last;'."\n".'      }'."\n".'    }'."\n";
    $code .= '    $y_num += $y_delta_step;'."\n";
    $code .= $self->{'flag'}{'sketch'}
           ? '    $y_pix -= SKETCH_FACTOR;'."\n"
           : '    $y_pix --;'."\n";
    $code .= '  }'."\n";
    $code .= '  $x_num += $x_delta_step;'."\n";
    $code .= $self->{'flag'}{'sketch'}
           ? '  $x_pix += SKETCH_FACTOR;'."\n"
           : '  $x_pix ++;'."\n";
    $code .= '}'."\n";

    #say "compile:",timestr(timediff(Benchmark->new, $t0));
    #$t0 = Benchmark->new();
    eval $code; # say $code;
    die "bad iter code - $@ :\n$code" if $@; # say "comp: ",timestr( timediff( Benchmark->new(), $t) );

    #say "run:",timestr(timediff(Benchmark->new, $t0));

    $dc->DrawBitmap( Wx::Bitmap->new( $img ), 0, 0, 0 );
    $self->{'image'} = $img unless $self->{'flag'}{'sketch'};

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
    # reuse $self->{'data'}{'image'}
    my $bmp = Wx::Bitmap->new( $width, $height, 24); # bit depth
    my $dc = Wx::MemoryDC->new( );
    $dc->SelectObject( $bmp );
    $self->paint( $dc, $width, $height);
    # $dc->Blit (0, 0, $width, $height, $self->{'dc'}, 10, 10 + $self->{'menu_size'});
    $dc->SelectObject( &Wx::wxNullBitmap );
    $bmp->SaveFile( $file_name, $file_end eq 'png' ? &Wx::wxBITMAP_TYPE_PNG : &Wx::wxBITMAP_TYPE_JPEG );
}

1;

__END__
