
# compute fractal image

package App::GUI::Juliagraph::Compute::Image;
use v5.12;
use warnings;
# use Benchmark;
use Graphics::Toolkit::Color qw/color/;
use Wx;
use App::GUI::Juliagraph::Widget::ProgressBar;
use App::GUI::Juliagraph::Compute::Mapping;

use constant SKETCH_FACTOR => 4;
# 'π' => 3.1415926535,  'τ' => 6.2831853071795,

my %progress_bar;
sub add_progress_bar {
    my( $name, $bar ) = @_;
    $progress_bar{$name} = $bar
        if ref $bar eq 'App::GUI::Juliagraph::Widget::ProgressBar'
        and not exists $progress_bar{$name};
}

sub compute_colors {
    my( $set, $max_iter ) = @_;
    my (@color_object, %gradient_mapping, $gradient_total_length, @color_value, $background_color);

    if ($set->{'mapping'}{'custom_partition'}){
        %gradient_mapping = %{ App::GUI::Juliagraph::Compute::Mapping::scales(
            $set->{'mapping'}{'scale_distro'}, $max_iter, $set->{'mapping'}{'scale_steps'}
        )};
        $gradient_total_length = $set->{'mapping'}{'scale_steps'};
    } else {
        $gradient_total_length = $max_iter;
    }

    if ($set->{'mapping'}{'user_colors'}){
        my $begin_nr = substr $set->{'mapping'}{'begin_color'}, 6;
        my $end_nr = substr $set->{'mapping'}{'end_color'}, 6;
        my $gradient_bases = 1 + abs( $begin_nr - $end_nr );

        my $gradient_part_length = ($gradient_bases == 1)
                                 ?  $gradient_total_length
                                 : 1 + int($gradient_total_length / ($gradient_bases - 1 ));
        my $gradient_direction = ( $begin_nr <= $end_nr ) ? 1 : -1;
        my $color_nr = $begin_nr;
        @color_object = map {color( $set->{'color'}{$color_nr} )} 1 .. $gradient_total_length if $gradient_bases == 1;
        for (1 .. $gradient_bases - 1) {
            my $start_color = color( $set->{'color'}{$color_nr} );
            $color_nr += $gradient_direction;
            # last partial gradient has to full it up to the end
            $gradient_part_length = $gradient_total_length - @color_object if $color_nr == $end_nr;
            push @color_object, $start_color->gradient( to => $set->{'color'}{ $color_nr },
                                                     steps => $gradient_part_length,
                                                        in => $set->{'mapping'}{'gradient_space'},
                                                      tilt => $set->{'mapping'}{'gradient_dynamic'} );
            pop @color_object if $color_nr != $end_nr;
        }
        $background_color = (substr($set->{'mapping'}{'background_color'}, 0, 5) eq 'color')
                          ? $set->{'color'}{'11'}
                          : $set->{'mapping'}{'background_color'};
        $background_color = '#001845' if $background_color eq 'blue';
        $background_color = color( $background_color );
    } else {
        @color_object = color('white')->gradient( to => 'black', steps => $max_iter,
                                                  in => $set->{'mapping'}{'gradient_space'},
                                             dynamic => $set->{'mapping'}{'gradient_dynamic'} );
        $background_color = $color_object[ -1 ];
    }

    if ($set->{'mapping'}{'use_subgradient'}){
        push @color_object, $color_object[-1];
        my %subgradient_mapping = %{ App::GUI::Juliagraph::Compute::Mapping::scales(
             $set->{'mapping'}{'subgradient_distro'},
             $set->{'mapping'}{'subgradient_size'},
             $set->{'mapping'}{'subgradient_steps'},
        )};
        for my $subgradient_nr (1 .. $max_iter) {
            my @subgradient = $color_object[$subgradient_nr - 1]->gradient(
                                              to => $color_object[$subgradient_nr],
                                           steps => $set->{'mapping'}{'subgradient_steps'},
                                              in => $set->{'mapping'}{'subgradient_space'},
                                            tilt => $set->{'mapping'}{'subgradient_dynamic'} );
            my @subcolor = map { [$_->values( 'RGB' )] } @subgradient;
            $color_value[$subgradient_nr - 1][$_] = $subcolor[ $subgradient_mapping{$_} ]
                    for 0 .. $set->{'mapping'}{'subgradient_size'} - 1;
        }
    } else {
        @color_value = map { [$_->values( 'RGB' )] } @color_object;
        if (%gradient_mapping){
            my @temp_color = @color_value;
            $color_value[$_] = $temp_color[ $gradient_mapping{$_} ] for 0 .. $max_iter-1;
        }
    }

    return \@color_value, [ $background_color->values( 'RGB' ) ];
}

sub from_settings {
    my( $set, $size, $sketch ) = @_;
    my $img = Wx::Image->new( $size->{'x'}, $size->{'y'} );
    my $sketch_factor = (defined $sketch) ? SKETCH_FACTOR : 0;
    #my $t0 = Benchmark->new();

    my $max_iter  =  int $set->{'constraint'}{'stop_nr'} ** 2;
    my $max_value =  int $set->{'constraint'}{'stop_value'} ** 2;
    my $zoom      = 140 * $set->{'constraint'}{'zoom'};
    my $schranke  = $max_value;

    my $color_index_max = $schranke + $set->{'mapping'}{'subgradient_size'};
    my ($colors, $background_color) = compute_colors( $set, $max_iter );
    for my $bar_name (keys %progress_bar){
        my $bar = $progress_bar{$bar_name};
        my $gradient_percent = 100 / @$colors;
        $bar->reset;
        next if $bar_name eq 'pen' and $sketch_factor;
        if ($bar_name eq 'background'){
            $bar->set_start_color( @$background_color );
            $bar->add_percentage( 100, $background_color );
        } else {
            if ($set->{'mapping'}{'use_subgradient'}){
                $bar->set_start_color( @{$colors->[0][0]} );

                my $subgradient_length = @{$colors->[0]};
                $gradient_percent /= $subgradient_length;
                my $color_counter = 0;
                for my $gradient_nr (0 .. $#$colors) {
                    for my $subgradient_pos (0 .. $subgradient_length - 1) {
                        $bar->add_percentage( $color_counter++ * $gradient_percent ,
                                              $colors->[$gradient_nr][$subgradient_pos] );
                    }
                }
            } else {
                $bar->set_start_color( @{$colors->[0]} );
                $bar->add_percentage( $_ * $gradient_percent , $colors->[$_] ) for 1 .. $#$colors;
            }
        }
        $bar->paint();
    }

    my $max_pixel_x  = $size->{x}-1;
    my $max_pixel_y  = $size->{y}-1;
    my $offset_x = (- $size->{'x'} / 2 / $zoom) + $set->{'constraint'}{'center_x'};
    my $offset_y = (- $size->{'y'} / 2 / $zoom) - $set->{'constraint'}{'center_y'};
    my $delta_x  = 1 / $zoom;
    my $delta_y  = 1 / $zoom;
    my $start_a  = $set->{'constraint'}{'start_a'};
    my $start_b  = $set->{'constraint'}{'start_b'};
    my $const_a  = $set->{'constraint'}{'const_a'};
    my $const_b  = $set->{'constraint'}{'const_b'};
    if ($sketch_factor){
        $delta_x *= $sketch_factor;
        $delta_y *= $sketch_factor;
        $max_pixel_x  /= $sketch_factor;
        $max_pixel_y  /= $sketch_factor;
    }

    my $max_power = 2;
    my %needed_power = ();
    my %existing_power = (1 => 1, 2 => 1);
    for my $monomial_nr (1 .. 4){
        next unless $set->{'monomial'}{$monomial_nr}{'active'};
        $needed_power{ $set->{'monomial'}{ $monomial_nr }{'exponent'} }++;
        $max_power = $set->{'monomial'}{ $monomial_nr }{'exponent'} if $max_power < $set->{'monomial'}{ $monomial_nr }{'exponent'};
    }
    my @monomial_code = '';
    for (my $power = 4; $power <= $max_power;$power *= 2){
        $existing_power{$power}++;
        my $half = $power / 2;
        push @monomial_code, '      $z['.$power.'][0] = ($z['.$half.'][0] * $z['.$half.'][0]) - ($z['.$half.'][1] * $z['.$half.'][1])'
                           , '      $z['.$power.'][1] =  2 * ($z['.$half.'][0] * $z['.$half.'][1])';
        delete $needed_power{$power} if exists $needed_power{$power};
    }
    for my $power (4, 2){
        for my $factor (3, 5, 7) {
            my $possible_power = $power * $factor;
            last if $possible_power > $max_power;
            for my $needed_power (keys %needed_power){
                if ($needed_power >= $possible_power and $needed_power < $possible_power + $factor){
                    my $base_power = $possible_power - $power;
                    push @monomial_code, '      $z['.$possible_power.'][0] = ($z['.$base_power.'][0] * $z['.$power.'][0]) - ($z['.$base_power.'][1] * $z['.$power.'][1])'
                                       , '      $z['.$possible_power.'][1] = ($z['.$base_power.'][0] * $z['.$power.'][1]) + ($z['.$base_power.'][1] * $z['.$power.'][0])';
                    delete $needed_power{ $possible_power } if exists $needed_power{ $possible_power };
                    $existing_power{ $possible_power }++;
                    last;
                }
            }
        }
    }
    for my $power (3,5,7,9,11,13,15){
        next unless $needed_power{ $power };
        my $base_power = $power - 1;
        push @monomial_code, '      $z['.$power.'][0] = ($z['.$base_power.'][0] * $za) - ($z['.$base_power.'][1] * $zb)'
                           , '      $z['.$power.'][1] = ($z['.$base_power.'][0] * $zb) + ($z['.$base_power.'][1] * $za)';
    }
    my ($a_term, $b_term) = ('$za = ', '$zb = ');
    for my $monomial_nr (1 .. 4){
        my $set = $set->{'monomial'}{ $monomial_nr };
        next unless $set->{'active'};
        my $sign = ($set->{'use_minus'}) ? '-' : '+';
        $a_term .= $sign . '(';
        $b_term .= $sign . '(';
        $a_term .= ($set->{'use_factor'}) ? $set->{'factor_r'}.' * ': '';
        $b_term .= ($set->{'use_factor'}) ? $set->{'factor_i'}.' * ': '';
        $a_term .= ($set->{'use_coor'}) ? ' $x * ': '';
        $b_term .= ($set->{'use_coor'}) ? ' $y * ': '';
        if ($set->{'use_log'}){
            $a_term .= ($set->{'exponent'} == 1) ? 'sqrt($zqa + $zqb))'
                                                 : 'sqrt($z['.$set->{'exponent'}.'][0]**2 + $z['.$set->{'exponent'}.'][1]**2))';
            $b_term .= ($set->{'exponent'} == 1) ? 'atan2($za,$zb))'
                                                 : 'atan2($z['.$set->{'exponent'}.'][0],$z['.$set->{'exponent'}.'][1]))';
        } else {
            $a_term .= ($set->{'exponent'} == 1) ? '$za)' : '$z['.$set->{'exponent'}.'][0])';
            $b_term .= ($set->{'exponent'} == 1) ? '$zb)' : '$z['.$set->{'exponent'}.'][1])';
        }

    }
    $a_term .= ' $za' if length($a_term) == 6; # self assign if no monomial is active
    $b_term .= ' $zb' if length($b_term) == 6;
    push @monomial_code, $a_term, $b_term;

    my $metric_code = {
        '|var|' => '$zqa + $zqb',      '|x*y|' => 'abs($za * $zb)',
          '|x|' => 'abs($za)',           '|y|' => 'abs($zb)',
        '|x+y|' => 'abs($za + $zb)', '|x|+|y|' => 'abs($za) + abs($zb)',
         'x+y'  => '$za + $zb',         'x*y'  => '$za * $zb',
         'x-y'  => '$za - $zb',         'y-x'  => '$za - $zb'}->{ $set->{'constraint'}{'stop_metric'} };

    my @bailout_code = (
        '      $metrik = '.$metric_code,
    ($set->{'mapping'}{'use_subgradient'})
     ? ('      $metrik = $color_index_max - 1 if $metrik >= $color_index_max',
        '      $color = $colors->[ $i ][$metrik-$schranke], last if $metrik >= $schranke' )
     :  '      $color = $colors->[ $i ], last if $metrik >= $schranke'
    );

    my @paint_code;
    if ($sketch_factor){
        push @paint_code, '    $px = $pixel_x * '.$sketch_factor, '    $py = $pixel_y * '.$sketch_factor;
        for my $x (0 .. $sketch_factor -1){
            for my $y (0 .. $sketch_factor -1){
                push @paint_code, '    $img->SetRGB( $px+'.$x.', $py+'.$y.', @$color)';
            }
        }
    } else {
        push @paint_code, '    $img->SetRGB( $pixel_x, $pixel_y, @$color)';
    }

    my (@z, $za, $zb, $zqa, $zqb, $color, $px, $py, $metrik);
    my $x = $offset_x;
    my @code = (
        'for my $pixel_x (0 .. $max_pixel_x){',
        '  my $y = $offset_y',
        '  for my $pixel_y (0 .. $max_pixel_y){',
       ($set->{'constraint'}{'coor_as_start'} ?
        '    ($za, $zb) = ($start_a + $x, $start_b + $y)' :
        '    ($za, $zb) = ($start_a, $start_b)' ),
        '    $zqa = $za * $za',
        '    $zqb = $zb * $zb',
        '    $color = $background_color',
        '    for my $i (0 .. $max_iter - 1){',
        '      ($z[2][0], $z[2][1]) = ($zqa - $zqb, 2 * $za * $zb)',
        @monomial_code,
        ($set->{'constraint'}{'coor_as_const'} ?
       ('      $za += $x + '.$const_a,
        '      $zb += $y + '.$const_b) :
       ('      $za += '.$const_a,
        '      $zb += '.$const_b,    ) ),
        '      $zqa = $za * $za',
        '      $zqb = $zb * $zb',
        @bailout_code,
        '    }', @paint_code,
        '    $y += $delta_y',
        '  }',
        '  $x += $delta_x',
        '}',
    );

    my $code = join '', map { $_ . ";\n"} @code;
    eval $code;
    die "bad iter code - $@ :\n$code" if $@; # say $code;
    #say "compile:",timestr(timediff(Benchmark->new, $t0));

    return $img;
}

1;
