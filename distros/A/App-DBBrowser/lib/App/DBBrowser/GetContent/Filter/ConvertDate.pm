package # hide from PAUSE
App::DBBrowser::GetContent::Filter::ConvertDate;

use warnings;
use strict;
use 5.014;

use DateTime::Format::Strptime;

use Term::Choose         qw();
use Term::Form::ReadLine qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::GetContent::Filter;


sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    bless $sf, $class;
    return $sf;
}


sub convert_date {
    my ( $sf, $sql, $bu_insert_args, $filter_str ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $rx_locale_dependent = "\%[aAbBhcpPxX]";
    my $aoa = $sql->{insert_args};
    my $row_count = @$aoa;
    my $busy_text = 'Convert datetime: ';
    my $threshold_busy = 5_000;
    my $threshold_progress = 100_000;
    my ( $working, $fmt, $step );
    if ( $row_count > $threshold_busy ) {
        $working = $busy_text . '...';
        if ( $row_count > $threshold_progress ) {
            $step = 1_000;
            my $total = int $row_count / $step;
            $fmt = $busy_text . $total . '/%' . length( $total ) . 'd';
        }
    }
    my $is_empty =  $cf->__search_empty_cols( $aoa );
    my $header = $cf->__prepare_header( $aoa, $is_empty );

    COL: while ( 1 ) {
        my $info = $cf->__get_filter_info( $sql, $filter_str);
        my $prompt = "Choose column:";
        # Stop
        my $col_idx = $cf->__choose_a_column_idx( $header, $info, $prompt );
        if ( ! defined $col_idx ) {
            return;
        }
        my $col = $header->[$col_idx];
        my @col_info = ( $filter_str, 'Column: ' . $col );
        $info = $cf->__get_filter_info( $sql, join( "\n", @col_info ) );

        SKIP_HEADER: while ( 1 ) {
            my @pre = ( undef );
            my ( $no, $yes ) = ( 'NO', 'YES' );
            my $row_idx_begin = 0;
            if ( $sf->{d}{stmt_types}[0] eq 'Create_Table' ) {
                # Choose
                my $choice = $tc->choose(
                    [ @pre, $yes, $no ],
                    { prompt => 'Skip the first row?', undef => $sf->{i}{s_back}, info => $info }
                );
                if ( ! defined $choice ) {
                    next COL;
                }
                $row_idx_begin = 1 if $choice eq $yes;
            }
            my $count_error_in = 0;
            my $default_pattern_in;

            IN: while ( 1 ) {
                my @in_info = @col_info;
                $info = $cf->__get_filter_info( $sql, join( "\n", @in_info ) );
                my $prompt_patter_in = 'Pattern in: ';
                # Readline
                my $pattern_in = $tr->readline(
                    $prompt_patter_in,
                    { info => $info, default => $default_pattern_in, history => $sf->__pattern_history( 'in' ) }
                );
                if ( ! length $pattern_in ) {
                    next SKIP_HEADER if $sf->{d}{stmt_types}[0] eq 'Create_Table';
                    next COL;
                }
                $default_pattern_in = $count_error_in > 1 ? '' : $pattern_in;
                push @in_info, $prompt_patter_in . $pattern_in;
                my $formatter_args = { pattern => $pattern_in };
                if ( $pattern_in =~ /$rx_locale_dependent/ ) {
                    $info = $cf->__get_filter_info( $sql, join( "\n", @in_info ) );
                    my $prompt_locale_in = 'Locale in: ';
                    # Readline
                    my $locale_in = $tr->readline(
                        $prompt_locale_in,
                        { info => $info, history => [] }
                    );
                    if ( length $locale_in ) {
                        $formatter_args->{locale} = $locale_in;
                        push @in_info, $prompt_locale_in . $locale_in;
                    }
                }
                my $formatter = DateTime::Format::Strptime->new( %$formatter_args, on_error  => 'undef' );

                TYPE: while ( 1 ) {
                    $info = $cf->__get_filter_info( $sql, join( "\n", @in_info ) );
                    my ( $format, $epoch ) = ( '- DateTime', '- Epoch' );
                    # Choose
                    my $choice = $tc->choose(
                        [ @pre, $format, $epoch ],
                        { %{$sf->{i}{lyt_v}}, prompt => 'To: ', undef => $sf->{i}{s_back}, info => $info }
                    );
                    if ( ! defined $choice ) {
                        ++$count_error_in;
                        next IN;
                    }
                    my $count_error_out = 0;
                    my $default_pattern_out;

                    OUT: while ( 1 ) {
                        my @tmp_info = @in_info;
                        if ( $choice eq $epoch ) {
                            $info = $cf->__get_filter_info( $sql, join( "\n", @tmp_info ) );
                            my ( $seconds, $milliseconds, $microseconds, $fract ) = ( '- Seconds', '- Milliseconds', '- Microseconds', '- Seconds.Fract' );
                            my $menu = [ @pre, $seconds, $milliseconds, $microseconds, $fract ];
                            # Choose
                            my $epoch_type = $tc->choose(
                                $menu,
                                { %{$sf->{i}{lyt_v}}, undef => $sf->{i}{s_back}, info => $info }
                            );
                            if ( ! defined $epoch_type ) {
                                next TYPE;
                            }
                            $cf->__print_busy_string( $working );
                            if ( ! eval {
                                for my $row ( $row_idx_begin .. $#$aoa ) {
                                    next if ! defined $aoa->[$row][$col_idx];
                                    my $dt = $formatter->parse_datetime( $aoa->[$row][$col_idx] );
                                    if ( ! defined $dt ) {
                                        for my $row ( 1 .. $row ) {
                                            $aoa->[$row][$col_idx] = $bu_insert_args->[$row][$col_idx];
                                        }
                                        my $message = $sf->__error_messagte_parse_datetime( $formatter, $row, $aoa->[$row][$col_idx] );
                                        die $message;
                                    }
                                    if ( $epoch_type eq $seconds ) {
                                        $aoa->[$row][$col_idx] = $dt->epoch();
                                    }
                                    elsif ( $epoch_type eq $milliseconds ) {
                                        $aoa->[$row][$col_idx] = int( $dt->hires_epoch() * 1_000 );
                                    }
                                    elsif ( $epoch_type eq $microseconds ) {
                                        $aoa->[$row][$col_idx] = int( $dt->hires_epoch() * 1_000_000 );
                                    }
                                    else {
                                        $aoa->[$row][$col_idx] = $dt->hires_epoch();
                                    }
                                    if ( $fmt && ! ( $row % $step ) ) {
                                        $cf->__print_busy_string( sprintf $fmt, $row / $step );
                                    }
                                }
                                1 }
                            ) {
                                $ax->print_error_message( $@ );
                                ++$count_error_in;
                                next IN;
                            }
                        }
                        else {
                            $info = $cf->__get_filter_info( $sql, join( "\n", @tmp_info ) );
                            my $prompt_pattern_out = 'Pattern out: ';
                            # Readline
                            my $pattern_out = $tr->readline(
                                $prompt_pattern_out,
                                { info => $info, default => $default_pattern_out, history => $sf->__pattern_history( 'out' ) }
                            );
                            if ( ! length $pattern_out ) {
                                next TYPE;
                            }
                            $default_pattern_out = $count_error_out > 1 ? '' : $pattern_out;
                            my $locale_out;
                            if ( $pattern_out =~ /$rx_locale_dependent/ ) {
                                push @tmp_info, $prompt_pattern_out . $pattern_out;
                                $info = $cf->__get_filter_info( $sql, join( "\n", @tmp_info ) );
                                my $prompt_locale_out = 'Locale out: ';
                                # ReadLine
                                $locale_out = $tr->readline(
                                    $prompt_locale_out,
                                    { info => $info, history => [] }
                                );
                                if ( length $locale_out ) {
                                    push @tmp_info, $prompt_locale_out . $locale_out;
                                }
                            }
                            $cf->__print_busy_string( $working );
                            if ( ! eval {
                                for my $row ( $row_idx_begin .. $#$aoa ) {
                                    next if ! length $aoa->[$row][$col_idx];
                                    my $dt = $formatter->parse_datetime( $aoa->[$row][$col_idx] );
                                    if ( ! defined $dt ) {
                                        for my $row ( 1 .. $row ) {
                                            $aoa->[$row][$col_idx] = $bu_insert_args->[$row][$col_idx];
                                        }
                                        my $message = $sf->__error_messagte_parse_datetime( $formatter, $row, $aoa->[$row][$col_idx] );
                                        die $message;
                                    }
                                    if ( length $locale_out ) {
                                        $dt->set_locale( $locale_out );
                                    }
                                    $aoa->[$row][$col_idx] = $dt->strftime( $pattern_out );
                                    if ( $fmt && ! ( $row % $step ) ) {
                                        $cf->__print_busy_string( sprintf $fmt, $row / $step );
                                    }
                                }
                                1 }
                            ) {
                                $ax->print_error_message( $@ );
                                if ( $@ =~ /^Pattern:/ ) {
                                    ++$count_error_in;
                                    next IN;
                                }
                                ++$count_error_out;
                                next OUT;
                            }
                        }
                        $sql->{insert_args} = $aoa;
                        return;
                    }
                }
            }
        }
    }
}


sub __error_messagte_parse_datetime {
    my ( $sf, $formatter, $row, $string ) = @_;
    my $message = 'Pattern: ' . $formatter->pattern() . ', ' . $formatter->locale();
    $message .= "\nRow: $row";
    $message .= "\nString: $string";
    $message .= "\n\n" . $formatter->errmsg();
    return $message;
}


sub __pattern_history {
    my ( $sf, $in_out ) = @_;
    if ( $in_out eq 'in' ) {
        my $in = [
            '%Y-%m-%d %H:%M:%S',
            '%Y-%m-%d %H:%M:%S.%N%z',
            '%a %d %b %Y %I:%M:%S %P',
            '%d.%m.%Y %H:%M:%S',
            '%d/%m/%Y %H:%M:%S',
            '%m/%d/%Y %H:%M:%S',
            '%y = two digit year (0-99)',
            '%b = Sep; %B = September',
            '%I = the hour on a 12-hour clock (01-12)',
            '%p = the equivalent of AM or PM according to the locale in use',
            '%z = timezone (eg. +2000);  %Z timezone name (eg. EST)',
            '%u = weekday number (1-7) with Monday is 1;  %w = weekday number (0-6) with Sunday is 0',
        ];
        return $in;
    }
    else {
        my $out = [
            '%Y-%m-%d %H:%M:%S',
            '%Y-%m-%d %H:%M:%S.%6N%z',
            $sf->{i}{driver} eq 'Oracle' ? '%d-%b-%y %I.%M.%S.%6N %p %Z' : '%a %d %b %Y %I:%M:%S.%6N %p %Z'
        ];
        return $out;
    }
}




1;


__END__
