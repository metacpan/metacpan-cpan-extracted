
# assemble code that calculates drawing

package App::GUI::Harmonograph::Compute::Drawing;
use v5.12;
use warnings;
use utf8;
use Graphics::Toolkit::Color qw/color/;
# use Benchmark;

my $TAU = 6.283185307;

sub gradient_steps {
    my $dots_per_gradient = shift;
    return ($dots_per_gradient > 500) ? 60 :
           ($dots_per_gradient > 50)  ? 20 : $dots_per_gradient;
}

sub calculate_colors {
    my ($set, $dot_count, $dot_per_sec) = @_;
    my $color_swap_time;
    my @colors = map { color( $set->{'color'}{$_} ) } 1 .. $set->{'visual'}{'colors_used'};
    $set = $set->{'visual'};

    if      ($set->{'color_flow_type'} eq 'one_time'){
        my $dots_per_gradient = int( $dot_count / $set->{'colors_used'} );
        my @color_objects = @colors;
        @colors = ($color_objects[0]);
        for my $i (0 .. $set->{'colors_used'}-2){
            pop @colors;
            push @colors, $color_objects[$i]->gradient(
                    to => $color_objects[$i+1],
                    steps => gradient_steps( $dots_per_gradient ),
                    tilt => $set->{'color_flow_dynamic'},
            );
        }
        $color_swap_time = int( $dot_count / @colors );
        $color_swap_time++ if $color_swap_time * @colors < $dot_count;
    }

    elsif ($set->{'color_flow_type'} eq 'alternate'){
        my $speed = $set->{'invert_flow_speed'} ? ( 1 / $set->{'color_flow_speed'}) : $set->{'color_flow_speed'};
        my $dots_per_gradient = int ($dot_per_sec * 60 / $speed);
        my $gradient_steps = gradient_steps( $dots_per_gradient );
        my @color_objects = @colors;
        my @c = ($color_objects[0]);
        for my $i (0 .. $set->{'colors_used'}-2){
            pop @c;
            push @c, $color_objects[$i]->gradient(
                    to => $color_objects[$i+1],
                    steps => $gradient_steps,
                    tilt => $set->{'color_flow_dynamic'},
            );
        }
        $color_swap_time = int( $dots_per_gradient / $gradient_steps );
        my $colors_needed = int( $dot_count / $color_swap_time   );
        $colors_needed++ while $colors_needed * $color_swap_time < $dot_count;
        @colors = @c;
        while ($colors_needed > @colors){
            @c = reverse @c;
            push @colors, @c[1 .. $#c];
        }
    }

    elsif ($set->{'color_flow_type'} eq 'circular'){
        my $speed = $set->{'invert_flow_speed'} ? ( 1 / $set->{'color_flow_speed'}) : $set->{'color_flow_speed'};
        my $dots_per_gradient = int ($dot_per_sec * 60 / $speed);
        my $gradient_steps = gradient_steps( $dots_per_gradient );
        my @color_objects = @colors;
        my @c = ($color_objects[0]);
        for my $i (0 .. $set->{'colors_used'}-2){
            pop @c;
            push @c, $color_objects[$i]->gradient(
                    to => $color_objects[$i+1],
                    steps => $gradient_steps,
                    tilt => $set->{'color_flow_dynamic'},
            );
        }
        pop @c;
        push @c, $color_objects[-1]->gradient(
                to => $color_objects[0],
                steps => $gradient_steps,
                tilt => $set->{'color_flow_dynamic'},
        );
        pop @c;
        $color_swap_time = int ($dots_per_gradient / $gradient_steps);
        my $colors_needed = int($dot_count / $color_swap_time );
        $colors_needed++ while $colors_needed * $color_swap_time < $dot_count;
        @colors = @c;
        push @colors, @c while $colors_needed > @colors;
    }
    return \@colors, $color_swap_time;
}

sub compile {
    my ($args, $main_radius) = @_;
    return unless ref $args eq 'HASH';
    my $set          = $args->{'settings'};
    my $progress_bar = $args->{'progress_bar'};

    my $Cr = $main_radius;
    my $board_size = 3 * $main_radius;
    # my $t = Benchmark->new();

    my $dot_per_sec = ($set->{'visual'}{'dot_density'} || 1);
    my $dot_count = ((exists $args->{'sketch'}) ? 5 : $set->{'visual'}{'duration'}) * $dot_per_sec;
    $set->{'visual'}{'connect_dots'} = int ($set->{'visual'}{'draw'} eq 'Line');

    my ($colors, $color_swap_time) = calculate_colors( $set, $dot_count, $dot_per_sec );
    my @colors = @$colors;
    my @wx_colors = map { Wx::Colour->new( $_->values ) } @colors;

    my @pendulum_names = qw/x y e f w r/;
    my @equation_names = qw/x y e f wx wy r11 r12 r21 r22/;
    $set->{$_}{'need_var'} = $set->{$_}{'on'} for @pendulum_names; # activate need of mod/function matrix
    for my $eq (@equation_names){
        next unless $set->{ substr $eq, 0, 1 }{'on'};
        my $pendulum_of_var = lc( substr $set->{'function'}{$eq.'_variable'}, 0, 1 );
        $set->{ $pendulum_of_var }{'need_var'} = 1
    }

    # init variables
    my @init_var_code;
    for my $pendulum_name (@pendulum_names){
        next unless $set->{$pendulum_name}{'need_var'};
        my $set = $set->{ $pendulum_name };
        my $index = uc $pendulum_name;
        my @code = ();
        push @code, 'my $f'.$index.' = '.($set->{'invert_dir'} ? '-' : '+').'1 '.
                                         ($set->{'invert_freq'} ? '/ ': '* ').($set->{'frequency'} * $set->{'freq_factor'});
        if ($set->{'freq_damp'}){
            push @code, 'my $df'.$index.' = $f'.$index.' / $dot_per_sec * '.($set->{'freq_damp'} * sqrt($set->{'freq_factor'}) / 10_000_000 );
            push @code, '$df'.$index.' /= $f'.$index if $set->{'invert_freq'};
            push @code, '$df'.$index.' = - $df'.$index if $set->{'invert_dir'};
            push @code, '$df'.$index.' = 1 - ($df'.$index.' * 20)' if $set->{'freq_damp_type'} eq '*';
            if ($set->{'freq_damp_acc'}){
                push @code, 'my $ddf'.$index.' = '.($set->{'freq_damp_acc'} / 50_000_000_000).' / $dot_per_sec';
                push @code, '$ddf'.$index.' /= $f'.$index if $set->{'invert_freq'};
                push @code, '$ddf'.$index.' = - $ddf'.$index if $set->{'invert_dir'};
                push @code, '$ddf'.$index.' = 1 - ($ddf'.$index.' * 20)'
                    if $set->{'freq_damp_acc_type'} eq '*' or $set->{'freq_damp_acc_type'} eq '/';
            }
        }
        push @code, '$r'.$index.' *= $Cr' unless $pendulum_name eq 'r';

        if ($set->{'radius_damp'}){
            my $code = 'my $dr'.$index.' = '.$set->{'radius_damp'}.' / $dot_per_sec / 8_000 * $r'.$index;
            $code .= '* $Cr' if $pendulum_name eq 'r';
            push @code, $code;
            push @code, '$dr'.$index.' = 1 - ($dr'.$index.' / 300 )' if $set->{'radius_damp_type'} eq '*';
            if ($set->{'radius_damp_acc'}){
                push @code, 'my $ddr'.$index.' = '.$set->{'radius_damp_acc'}.' / $dot_per_sec / 20_000';
                push @code, '$ddr'.$index.' = 1 - ($ddr'.$index.(($set->{'radius_damp_type'} eq '*') ? '/ 400 ' : '* 40 ').' )'
                    if $set->{'radius_damp_acc_type'} eq '*' or $set->{'radius_damp_acc_type'} eq '/';
            }
        }
        push @code, 'my $t'.$index.' = '.$set->{'offset'},
                    'my $dt'.$index.' = $f'.$index.' / '.$dot_per_sec;
        push @init_var_code, @code;
    }

    # update variables
    my @update_var_code;
    for my $pendulum_name (@pendulum_names){
        next unless $set->{$pendulum_name}{'need_var'};
        my $set = $set->{ $pendulum_name };
        my $index = uc $pendulum_name;
        my @code = ('  $t'.$index.' += $dt'.$index);
        if ($set->{'freq_damp'}){
            my $code = '  $dt'.$index.' '.$set->{'freq_damp_type'}.'= $df'.$index;
            $code .= ' if $dt'.$index.' > 0' if not $set->{'neg_freq'} and $set->{'freq_damp_type'} eq '-';
            push @code, $code;
            push @code, '  $df'.$index.' '.$set->{'freq_damp_acc_type'}.'= $ddf'.$index if $set->{'freq_damp_acc'};
        }
        if ($set->{'radius_damp'}){
            my $code = '  $r'.$index.' '.$set->{'radius_damp_type'}.'= $dr'.$index;
            $code .= ' if $r'.$index.' > 0' if not $set->{'neg_radius'} and $set->{'radius_damp_type'} eq '-';
            push @code, $code;
            push @code, '  $dr'.$index.' '.$set->{'radius_damp_acc_type'}.'= $ddr'.$index if $set->{'radius_damp_acc'};
        }
        push @update_var_code, @code;
    }

    my %var_names = ( 'X time' => '$tX', 'X freq.' => '$dtX', 'X radius' => '$rX',
                      'Y time' => '$tY', 'Y freq.' => '$dtY', 'Y radius' => '$rY',
                      'E time' => '$tE', 'E freq.' => '$dtE', 'E radius' => '$rE',
                      'F time' => '$tF', 'F freq.' => '$dtF', 'F radius' => '$rF',
                      'W time' => '$tW', 'W freq.' => '$dtW', 'W radius' => '$rW',
                      'R time' => '$tR', 'R freq.' => '$dtR', 'R radius' => '$rR');

    # compute coordinates
    my @compute_coor_code;
    my ( $termX, $termY, $termE, $termF, $termWX, $termWY, $termR11, $termR12, $termR21, $termR22, $explus, $exminus );
    for my $eq (@equation_names){
        my $pendulum_name = substr( $eq, 0, 1 );
        next unless $set->{$pendulum_name}{'on'};
        my $state = $set->{'function'};
        my $factor = $state->{$eq.'_factor'} * $state->{$eq.'_constant'};
        my $op = $state->{$eq.'_operator'};
        my $var = $var_names{ $state->{$eq.'_variable'} };
        my $funct = $state->{$eq.'_function'};
        my $term_var = '$term'.uc($eq);

        my $next = '  '.($set->{'visual'}{'connect_dots'} ? '$line_broke = 1, ' : ''). 'next unless ';
        my $assign  = '  '.$term_var.' = ';
        my $mod      = $term_var.' - int '.$term_var;
        my $norm      = $assign.$TAU.' * ('.$mod.')';
        my $norm_half = $assign.$TAU.' * (('.$mod.') -0.5)';
        my $norm_double = $assign.$TAU.' * (('.$mod.') * 2 - 1)';
        my @exp = ('$explus = exp'.$term_var, '$exminus = exp -'.$term_var);

        push @compute_coor_code, $next.$var if $op eq '/';
        push @compute_coor_code, $assign.($op eq '=' ? '' : '$t'.uc($pendulum_name)." $op ")
                                        .'('.$factor.' * '. $var.')';

        if    ($funct eq 'sin') {push @compute_coor_code, $norm, $assign.'sin '.$term_var }
        elsif ($funct eq 'cos') {push @compute_coor_code, $norm, $assign.'cos '.$term_var }
        elsif ($funct eq 'tan') {push @compute_coor_code, $norm_half, $next.'cos '.$term_var,
                                                          $assign.'sin('.$term_var.')/cos('.$term_var.')' }
        elsif ($funct eq 'cot') {push @compute_coor_code, $norm_half, $next.'sin '.$term_var,
                                                          $assign.'cos('.$term_var.')/sin('.$term_var.')' }
        elsif ($funct eq 'sec') {push @compute_coor_code, $norm, $next.'cos '.$term_var,
                                                          $assign.'1/cos('.$term_var.')' }
        elsif ($funct eq 'csc') {push @compute_coor_code, $norm, $next.'sin '.$term_var,
                                                          $assign.'1/sin('.$term_var.')' }
        elsif ($funct eq 'sinh'){push @compute_coor_code, $norm_double,
                                                          $assign.'0.5 * (exp('.$term_var.') - exp(-'.$term_var.'))' }
        elsif ($funct eq 'cosh'){push @compute_coor_code, $norm_double,
                                                          $assign.'0.5 * (exp('.$term_var.') + exp(-'.$term_var.'))' }
        elsif ($funct eq 'tanh'){push @compute_coor_code, $norm_double, @exp, $next.'$explus + $exminus',
                                                          $assign.'($explus - $exminus)/($explus + $exminus)'; }
        elsif ($funct eq 'coth'){push @compute_coor_code, $norm_double, @exp, $next.'$explus - $exminus',
                                                          $assign.'($explus + $exminus)/($explus - $exminus)'; }
        elsif ($funct eq 'sech'){push @compute_coor_code, $norm_double, @exp, $next.'$explus + $exminus',
                                                          $assign.'1 / ($explus + $exminus)'; }
        elsif ($funct eq 'csch'){push @compute_coor_code, $norm_double, @exp, $next.'$explus - $exminus',
                                                          $assign.'1 / ($explus - $exminus)'; }
    }
    push @compute_coor_code, '  $x = '.($set->{'x'}{'on'} ? '$rX * $termX' : '0')
                           , '  $y = '.($set->{'y'}{'on'} ? '$rY * $termY' : '0');
    push @compute_coor_code, '  $x += $rE * $termE' if $set->{'e'}{'on'};
    push @compute_coor_code, '  $y += $rF * $termF' if $set->{'f'}{'on'};
    push @compute_coor_code, ' ($x, $y) = ($rR * (($x * $termR11) - ($y * $termR12))'
                                        .',$rR * (($x * $termR21) + ($y * $termR22)))' if $set->{'r'}{'on'}
                                                                        and $set->{'function'}{'first_rotary'} eq 'r';
    push @compute_coor_code, '  $x -= $rW * $termWX'
                           , '  $y -= $rW * $termWY' if $set->{'w'}{'on'};
    push @compute_coor_code, ' ($x, $y) = ($rR * (($x * $termR11) - ($y * $termR12))'
                                        .',$rR * (($x * $termR21) + ($y * $termR22)))' if $set->{'r'}{'on'}
                                                                        and $set->{'function'}{'first_rotary'} eq 'w';
    push @compute_coor_code, '  $x += $Cx', '  $y += $Cy';


    my $pen_size = $set->{'visual'}{'line_thickness'} - .5;
    my $wxpen_style = { dotted => &Wx::wxPENSTYLE_DOT,        short_dash => &Wx::wxPENSTYLE_SHORT_DASH,
                        solid => &Wx::wxPENSTYLE_SOLID,       vertical => &Wx::wxPENSTYLE_VERTICAL_HATCH,
                        horizontal => &Wx::wxPENSTYLE_HORIZONTAL_HATCH, cross => &Wx::wxPENSTYLE_CROSS_HATCH,
                        diagonal => &Wx::wxPENSTYLE_BDIAGONAL_HATCH, bidiagonal => &Wx::wxPENSTYLE_CROSSDIAG_HATCH};
    my $pen_style = $wxpen_style->{ $set->{'visual'}{'pen_style'} };
    my $pen_probability = $set->{'visual'}{'dot_probability'} /= 100;

    my @code = ('sub {','my ($dc, $Cx, $Cy) = @_');
    push @code, 'my $r'.uc($_).' = '.($set->{$_}{'radius'} * $set->{$_}{'radius_factor'}) for qw/x y e f w/;
    push @code, 'my $rR = '.$set->{'r'}{'radius'};
    push @code, ($set->{'x'}{'on'} ? 'my $max_xr = $rX' : 'my $max_xr = 1');
    push @code, ($set->{'y'}{'on'} ? 'my $max_yr = $rY' : 'my $max_yr = 1');
    push @code, '$max_xr += $rE' if $set->{'e'}{'on'};
    push @code, '$max_yr += $rF' if $set->{'f'}{'on'};
    push @code, '$max_xr += $rW', '$max_yr += $rW' if $set->{'w'}{'on'};
    push @code, '$max_xr *= 1.4', '$max_yr *= 1.4' if $set->{'r'}{'on'};


    push @code, '$Cr /= (($max_xr > $max_yr) ? $max_xr : $max_yr)'; # zoom out so everything is visible
    push @code, @init_var_code, 'my ($x, $y)';
    push @code, 'my ($x_old, $y_old)','my $line_broke = 1' if $set->{'visual'}{'connect_dots'};
    push @code, '$dc->SetPen( Wx::Pen->new( shift @wx_colors, $pen_size, $pen_style ) )',
                'my $first_color = shift @colors';
    push @code, 'my $color_timer = 0' if $color_swap_time;
    push @code, 'for my $i (1 .. $dot_count){';
    if ($color_swap_time){
        push @code, '  if ($color_timer++ == $color_swap_time){', '    $color_timer = 1',
                    '    $dc->SetPen( Wx::Pen->new( shift @wx_colors, $pen_size, $pen_style) )';
        push @code, '    $progress_bar->add_percentage( ($i/ $dot_count*100), [(shift @colors)->values] )' unless exists $args->{'sketch'};
        push @code, '  }';
    }
    push @code, @compute_coor_code, @update_var_code;
    push @code, '  next if rand(1) > $pen_probability' if $pen_probability < 1;
    push @code, ($set->{'visual'}{'connect_dots'}
              ? ('  if ($line_broke) {$line_broke = 0; ($x_old, $y_old) = ($x, $y) }',
                 '  if ($x < 0 or $x > $board_size or $y < 0 or $y > $board_size) {$line_broke++; next}',
                '  $dc->DrawLine( $x_old, $y_old, $x, $y)',
                '  ($x_old, $y_old) = ($x, $y)' )
              : '  $dc->DrawPoint( $x, $y )');
    push @code, '}';
    push @code, '$progress_bar->add_percentage( 100, [$first_color->values] )' unless exists $args->{'sketch'} or $color_swap_time ;

    my $code = join '', map {$_.";\n"} @code, '}'; # say $code;
    my $code_ref = eval $code;
    die "bug '$@' in drawing code: $code" if $@;   # say "comp: ",timestr( timediff( Benchmark->new(), $t) );
    return $code_ref;
}


1;
