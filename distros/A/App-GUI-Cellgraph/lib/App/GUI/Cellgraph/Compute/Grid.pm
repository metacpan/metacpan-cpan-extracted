
# compute each cells state and action value

package App::GUI::Cellgraph::Compute::Grid;
use v5.12;
use warnings;
use Wx;
use Benchmark;

sub create {
    my ($state, $grid_size, $sketch_length) = @_;
    return unless defined $grid_size and ref $state eq 'HASH' and exists $state->{'global'}{'input_size'};
    my $grid_circular = $state->{'global'}{'grid_circular'};
    my $grow_direction = $state->{'global'}{'paint_direction'};
    my $result_calc = $state->{'rules'}{'calc'};
    my $inputs = $state->{'global'}{'input_size'};
    my $state_count = $state->{'global'}{'state_count'};
    my $input_overhang = int $inputs / 2;
    my $self_input     = $inputs % 2;
    my $odd_grid_size  = $grid_size % 2;
    my $half_grid_size = int($grid_size / 2);
    # my $t0 = Benchmark->new;

    my @start_states = @{ $state->{'start'}{'state_list'} };
    if ($state->{'start'}{'repeat_states'}) { # repeat first row into left and right direction
        my @repeat = @start_states;
        my $prepend_length = int( ($grid_size - @start_states) / 2);
        unshift @start_states, @repeat for 1 .. $prepend_length / @repeat;
        unshift @start_states, @repeat[ $#repeat - ( $prepend_length % @repeat) .. $#repeat];
        my $append_length = $grid_size - @start_states;
        push @start_states, @repeat for 1 .. $append_length / @repeat;
        push @start_states, @repeat[0 .. $append_length % @repeat];
    } else {
        if (@start_states < $grid_size) { # center predefined first row
            push @start_states, (0) x int( ($grid_size - @start_states) / 2);
            unshift @start_states, (0) x ($grid_size - @start_states);
        } else { splice @start_states, $grid_size }
    }
    my @start_action = map {$_/5} @{ $state->{'start'}{'action_list'} };
    if ($state->{'start'}{'repeat_action'}) { # repeat first row into left and right direction
        my @repeat = @start_action;
        my $prepend_length = int( ($grid_size - @start_action) / 2);
        unshift @start_action, @repeat for 1 .. $prepend_length / @repeat;
        unshift @start_action, @repeat[ $#repeat - ( $prepend_length % @repeat) .. $#repeat];
        my $append_length = $grid_size - @start_action;
        push @start_action, @repeat for 1 .. $append_length / @repeat;
        push @start_action, @repeat[0 .. $append_length % @repeat];
    } else {
        if (@start_action < $grid_size) { # center predefined first row
            push @start_action, (0) x int( ($grid_size - @start_action) / 2);
            unshift @start_action, (0) x ($grid_size - @start_action);
        } else { splice @start_action, $grid_size }
    }

    my $state_grid  = [ [@start_states] ];
    my $paint_grid  = [ [] ];
    my @empty_row   =  (0) x $grid_size;
    my $row_start = "'".('0' x $input_overhang)."'";
    my @cell_states = @start_states;
    my @cell_action = @start_action;
    my (@subrule_nr, @prev_states, @prev_action);
    my $compute_right_stop = $grid_size - 1 - $input_overhang;
    my $compute_rows = ($sketch_length)                ? $sketch_length :
                       ($grow_direction eq 'top_down') ? $grid_size     :
                                                         ($half_grid_size + $odd_grid_size);
    my %subrule_from_pattern = map {$_ => $result_calc->subrules->effective_pattern_nr( $_ )} $result_calc->subrules->all_pattern;
    my %result_from_subrule  = map {$_ => $result_calc->get_subrule_result( $_ )} $result_calc->subrules->index_iterator;

    my @action_result_from_subrule = @{$state->{'action'}{'result_list'}};
    my @action_spread_from_subrule = @{$state->{'action'}{'spread_list'}};
    my @action_spread_decrease = ($state->{'global'}{'action_spread'}) ? (map
        { ($action_spread_from_subrule[$_] - $action_result_from_subrule[$_]) / $state->{'global'}{'action_spread'} }
            $result_calc->subrules->index_iterator) : ();
    my @init_spread = ( (0) x ($grid_size - 1 + (2 * int($state->{'global'}{'action_spread'}))) );
    my $result_op = $state->{'global'}{'result_application'};
    my $state_max = $result_calc->subrules->independent_count;
    my $next_result = ($result_op eq 'insert')   ? '$subrule_nr[$_]' :
                      ($result_op eq 'rotate')   ? '(               1 + $subrule_nr[$_]) % $state_max' :
                      ($result_op eq 'add')      ? '($cell_states[$_] + $subrule_nr[$_]) % $state_max' :
                      ($result_op eq 'add_rot')  ? '($cell_states[$_]+1+$subrule_nr[$_]) % $state_max' :
                      ($result_op eq 'subtract') ? '($cell_states[$_] - $subrule_nr[$_] + $state_max) % $state_max' :
                                                   '($cell_states[$_] * $subrule_nr[$_]) % $state_max' ;
    $next_result = ' $result_from_subrule{ '.$next_result.' } ';
    $next_result = ' ($cell_action[$_] >= '.$state->{'global'}{'action_threshold'}.
                    ') ? '.$next_result.' : $cell_states[$_] ' if $state->{'global'}{'action_rules_apply'};


    my $code =     'for my $row_nr (1 .. '.($compute_rows - 1).') {'."\n".
                   (($state->{'global'}{'action_spread'}) ? '  my @action_spread = @init_spread;'."\n" :'').
                   '  @prev_states = @cell_states;'."\n";


    my $code_end = '  @cell_states = map { '.$next_result.' } 0 .. '.($grid_size-1).";\n\n".
                   '  $state_grid->[$row_nr] = [@cell_states];'."\n".'}';

    if ($state->{'global'}{'action_rules_apply'}){
        $code .=    '  @prev_action = @cell_action;'."\n";
        my $calc_action = '  @cell_action = map { $action_result_from_subrule[$_] } @subrule_nr'.";\n".
                          '  @cell_action = map { $cell_action[$_] + $prev_action[$_] + '.$state->{'global'}{'action_change'}.' } 0 .. '.($grid_size-1).";\n";
        $calc_action.= '  for my $x ( 0 .. '.($grid_size-1).' ) { '."\n".
                       '    my $real_pos = $x + '.$state->{'global'}{'action_spread'}.";\n".
                       '    my $action = $cell_action[$x];'."\n".
                       '    my $delta = my $decrease = $action_spread_decrease[ $subrule_nr[$x] ];'."\n".
                       '    for my $d (1..'.$state->{'global'}{'action_spread'}.') { '."\n".
                       '      $action_spread[$real_pos + $d ] += $action + $delta;'."\n".
                       '      $action_spread[$real_pos - $d ] += $action - $delta;'."\n".
                       '      $delta += $decrease'."\n".
                       '  }}'."\n".
                       '  @cell_action = map { $cell_action[$_] + $action_spread[$_+'.$state->{'global'}{'action_spread'}.'] } 0 .. '.($grid_size-1).";\n"
                          if $state->{'global'}{'action_spread'};

        $calc_action   .= '  @cell_action = map { ($_ < 0) ? 0 : ($_ > 1) ? 1 : $_ } @cell_action'.";\n";
        $code_end = $calc_action . $code_end;
    }

    my $wrap_overhang = 'join("", @prev_states[-'.$input_overhang.' .. -1])';
    my $right_overhang = 'join("", @prev_states[0 .. '.$input_overhang.'-1])';

    if ($self_input) {
        my $eval_pattern = '$subrule_from_pattern{ $pattern }';
        $code .= '  my $pattern = "0".'
              .($grid_circular ? $wrap_overhang : $row_start).'.'.$right_overhang.";\n"
              .'  for my $x_pos (0 .. '.$compute_right_stop.'){'."\n"
              .'  '.move_pattern_string('$pattern','$x_pos+'.$input_overhang)
              .'    $subrule_nr[$x_pos] = '.$eval_pattern.";\n  }\n"
              .'  for my $x_pos ('.($compute_right_stop + 1).' .. '.($grid_size - 1).'){'."\n"
              .'  '.move_pattern_string('$pattern', ($grid_circular ? '$x_pos+'.($input_overhang - $grid_size) : undef ))
              .'    $subrule_nr[$x_pos] = '.$eval_pattern.";\n  }\n\n";
    } else {
        my $eval_pattern = '$subrule_from_pattern{ $left_pattern.$right_pattern }';
        $code .= '  my $left_pattern = '.($grid_circular ? $wrap_overhang : $row_start).";\n"
              .  '  my $right_pattern = join("", @prev_states[1 .. '.$input_overhang.']);'."\n"
              .  '  $subrule_nr[0] = '.$eval_pattern.";\n\n"
              .  '  for my $x_pos (1 .. '.$compute_right_stop.'){'."\n"
              .  '  '.move_pattern_string('$left_pattern','$x_pos-1')
              .  '  '.move_pattern_string('$right_pattern','$x_pos+'.$input_overhang)
              .  '    $subrule_nr[$x_pos] = '.$eval_pattern.";\n  }\n"
              .  '  for my $x_pos ('.($compute_right_stop+1).' .. '.($grid_size - 1).'){'."\n"
              .  '  '.move_pattern_string('$left_pattern','$x_pos-1')
              .  '  '.move_pattern_string('$right_pattern', ($grid_circular ? '$x_pos+'.($input_overhang - $grid_size) : undef) )
              .  '    $subrule_nr[$x_pos] = '.$eval_pattern.";\n  }\n\n";
    }

    #say $code . $code_end;
    my $result = eval( $code . $code_end);
    say "compile in code:\n$code\n\n error: $@" if $@;
    # say "got grid in:",timestr( timediff(Benchmark->new, $t0) );

    if ($sketch_length){
        $state_grid->[$_] = [@empty_row] for $compute_rows .. $grid_size - 1;
        return $state_grid;
    }
    return $state_grid if $grow_direction eq 'top_down';

    # implementing paint directions
    if ($grow_direction eq 'inside_out') {
        $paint_grid->[$half_grid_size][$half_grid_size]
            = $state_grid->[0][$half_grid_size] if $odd_grid_size;      # center cell state

        for my $y_pos ($odd_grid_size .. $half_grid_size - 1 + $odd_grid_size){
            my $cy_pos = $half_grid_size - $y_pos - 1 + $odd_grid_size; # mirror on Center pos
            my $dy_pos = $half_grid_size + $y_pos;
            for my $x_pos ($half_grid_size - $y_pos .. $half_grid_size + $y_pos){
                my $bx_pos = $grid_size - 1 - $x_pos;
                $paint_grid->[$cy_pos][$bx_pos] = $paint_grid->[$bx_pos][$dy_pos] =
                $paint_grid->[$dy_pos] [$x_pos] = $paint_grid-> [$x_pos][$cy_pos] = $state_grid->[$y_pos][$x_pos];
            }
        }
    }
    if ($grow_direction eq 'outside_in') {
        $paint_grid->[$half_grid_size][$half_grid_size]
            = $state_grid->[$half_grid_size][$half_grid_size] if $odd_grid_size; # center cell state

        for my $y_pos (0 .. $half_grid_size - 1){
            my $by_pos = $grid_size - 1 - $y_pos;
            for my $x_pos ($y_pos .. $by_pos - 1){
                my $bx_pos = $grid_size - 1 - $x_pos;
                $paint_grid->[$y_pos] [$x_pos]  = $paint_grid->[$x_pos] [$by_pos] =
                $paint_grid->[$by_pos][$bx_pos] = $paint_grid->[$bx_pos][$y_pos]  = $state_grid->[$y_pos][$x_pos];
            }
        }
    }
    $paint_grid;
}

sub move_pattern_string {
    my ($var, $index) = @_;
    my $str = '  '.$var.' = substr('.$var.',1).';
    $str .= (defined $index) ? '$prev_states['.$index.']': "'0'";
    return $str.";\n";
}

1;
__END__
