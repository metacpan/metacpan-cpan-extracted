package # hide from PAUSE
App::DBBrowser::GetContent::Parse;

use warnings;
use strict;
use 5.010001;

use Encode qw( decode );

use Encode::Locale    qw();
#use Spreadsheet::Read qw( ReadData rows ); # required
#use String::Unescape  qw( unescape );      # required
#use Text::CSV         qw();                # required

use Term::Choose           qw();
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( get_term_size get_term_width unicode_sprintf insert_sep );
use Term::Form             qw();


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
    };
    bless $sf, $class;
}

use Term::Choose::Screen qw( clear_screen );

sub __print_waiting_str {
    my ( $sf ) = @_;
    print clear_screen;
    print 'Parsing file ... ' . "\r";
}


sub __parse_plain {
    my ( $sf, $sql, $fh ) = @_;
    my $rows_of_cols = [];
    my $file_fs = $sf->{i}{f_plain};
    require Text::CSV;
    $rows_of_cols = Text::CSV::csv( in => $file_fs ) or die Text::CSV->error_diag;
    $sql->{insert_into_args} = $rows_of_cols;
    return 1;
}


sub __parse_with_Text_CSV {
    my ( $sf, $sql, $fh ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $sf->__print_waiting_str;
    seek $fh, 0, 0;
    my $rows_of_cols = [];
    require String::Unescape;
    my $options = { map { $_ => String::Unescape::unescape( $sf->{o}{csv}{$_} ) } keys %{$sf->{o}{csv}} };
    require Text::CSV;
    my $csv = Text::CSV->new( $options ) or die Text::CSV->error_diag();
    $csv->callbacks( error => sub {
        my ( $code, $str, $pos, $rec, $fld ) = @_;
        if ( $code == 2012 ) { # ignore this error
            Text::CSV->SetDiag (0);
        }
        else {
            my $error_input = $csv->error_input() // 'No Error Input defined.';
            my $prompt = "Error Input:";
            $error_input =~ s/\R/ /g;
            my $info = "Close with ENTER\nText::CSV\n$code $str\nposition:$pos record:$rec field:$fld\n";
            $tc->choose(
                [ line_fold( $error_input, get_term_width() ) ],
                { info => $info, prompt => $prompt  }
            );
            $ax->print_sql_info( $info );
            return;
        }
    } );
    while ( my $cols = $csv->getline( $fh ) ) {
        push @$rows_of_cols, $cols;
    }
    $sql->{insert_into_args} = $rows_of_cols;
    return 1;
}


sub __parse_with_split {
    my ( $sf, $sql, $fh ) = @_;
    $sf->__print_waiting_str;
    my $rows_of_cols = [];
    local $/;
    seek $fh, 0, 0;
    my $record_lead  = $sf->{o}{split}{record_l_trim};
    my $record_trail = $sf->{o}{split}{record_r_trim};
    my $field_lead   = $sf->{o}{split}{field_l_trim};
    my $field_trail  = $sf->{o}{split}{field_r_trim};
    for my $row ( split /$sf->{o}{split}{record_sep}/, <$fh> ) {
        $row =~ s/^$record_lead//   if length $record_lead;
        $row =~ s/$record_trail\z// if length $record_trail;
        push @$rows_of_cols, [
            map {
                s/^$field_lead//   if length $field_lead;
                s/$field_trail\z// if length $field_trail;
                $_
            } split /$sf->{o}{split}{field_sep}/, $row, -1 ]; # negative LIMIT (-1) to preserve trailing empty fields
    }
    $sql->{insert_into_args} = $rows_of_cols;
    return 1;
}


sub __print_template_info {
    my ( $sf, $rows, $occupied_term_h ) = @_;
    my ( $term_w, $term_h ) = get_term_size();
    my $tapeline = '123456789*';
    my $ruler;
    $ruler .= $tapeline x int( $term_w / 10 );
    $ruler .= substr( $tapeline, 0, ( $term_w % 10 ) );
    my $info = $ruler;
    my $avail_h = $term_h - $occupied_term_h;
    if ( $avail_h < 5 ) { ##
        $avail_h = 5;
    }
    my $first_part_end = int( $avail_h / 1.5 );
    my $second_part_begin = $avail_h - $first_part_end;
    $first_part_end--;
    $second_part_begin--;
    my $end_idx = $#{$rows};
    my $dots = $sf->{i}{dots}[ $sf->{o}{G}{dots} ];
    if ( @$rows > $avail_h ) {
        for my $row ( @{$rows}[ 0 .. $first_part_end ] ) {
            $info .= "\n" . unicode_sprintf( $row, $term_w, { mark_if_truncated => $dots } );
        }
        $info .= "\n[...]";
        for my $row ( @{$rows}[ $end_idx - $second_part_begin .. $end_idx ] ) {
            $info .= "\n" . unicode_sprintf( $row, $term_w, { mark_if_truncated => $dots } );
        }
        my $row_count = scalar( @$rows );
        $info .= "\n" . unicode_sprintf( '[' . insert_sep( $row_count, $sf->{o}{G}{thsd_sep} ) . ' rows]', $term_w, { mark_if_truncated => $dots } );
    }
    else {
        for my $row ( @$rows ) {
            $info .= "\n" . unicode_sprintf( $row, $term_w, { mark_if_truncated => $dots } );
        }
    }
    $info .= "\n";
    return $info;
}


sub __parse_with_template {
    my ( $sf, $sql, $fh ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $old_idx = 0;

    IRS: while ( 1 ) {
        my $prompt = 'Choose the Input record separator:';
        my @irs = ( "\\n", "\\r", "\\r\\n" );
        my $reparse = '  Reparse';
        my @pre = ( undef );
        my $menu = [ @pre, map( '  "' . $_ . '"', @irs ), $reparse ];
        my $info = "Parse mode: Template\n";
        # Choose
        my $idx = $tc->choose(
            $menu,
            { prompt => $prompt, index => 1, default => $old_idx, layout => 3, undef => '  <=', clear_screen => 1, info => $info }
        );
        $ax->print_sql_info( $info );
        if ( ! $idx ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next IRS;
            }
            $old_idx = $idx;
        }
        if ( $menu->[$idx] eq $reparse ) {
            require App::DBBrowser::Opt::Set;
            require App::DBBrowser::GetContent;
            my $gc = App::DBBrowser::GetContent->new( $sf->{i}, $sf->{o} );
            my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
            $sf->{o} = $opt_set->set_options( [ { name => 'group_insert', text => '' } ] );
            return -1;
        }
        require String::Unescape;
        $/ = String::Unescape::unescape( $irs[$idx-@pre] );
        $sf->__print_waiting_str;
        seek $fh, 0, 0;
        my @rows = grep { ! /^\s+\z/ } <$fh>;
        chomp @rows;

        COL_COUNT: while ( 1 ) {
            my $info = $sf->__print_template_info( \@rows, 9 );
            # Choose a number
            my $col_count = $tu->choose_a_number( 2,
                { clear_screen => 1, info => $info, cs_label => 'Number of columns: ',
                  small_first => 1, confirm => 'Confirm', back => 'Back' }
            );
            $ax->print_sql_info( $info );
            if ( ! $col_count ) {
                next IRS;
            }
            my $col_names = [ map { 'c' . $_ } 1 .. $col_count ];
            my $fields = [ map { [ $_, ] } @$col_names ];

            COL_WIDTHS: while ( 1 ) {
                my $info = $sf->__print_template_info( \@rows, 7 + $col_count );
                # Fill_form
                my $form = $tf->fill_form(
                    $fields,
                    { info => $info, prompt => 'Col widths:', auto_up => 2,
                    confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back} . '   ' }
                );
                $ax->print_sql_info( $info );
                if ( ! $form ) {
                    next COL_COUNT;
                }
                my @values;
                for my $field ( @$form ) {
                    my ( $field_name, $field_value ) = @$field;
                    my $prompt;
                    if ( ! defined $field_value || ! length $field_value ) {
                        $prompt = "$field_name: value not defined!";
                    }
                    elsif ( $field_value !~ /^(?:0|[1-9][0-9]*)\z/ ) {
                        $prompt = "$field_name: \"$field_value\" is not 0 or greater!";
                    }
                    if ( defined $prompt ) {
                        my $info = $sf->__print_template_info( \@rows, 6 );
                        $tc->choose(
                            [ 'Press ENTER' ],
                            { info => $info, prompt => $prompt, info => $info }
                        );
                        $ax->print_sql_info( $info );
                        @$fields = @$form;
                        next COL_WIDTHS;
                    }
                    push @values, $field_value;
                }
                my $prompt = 'Remove leading Spaces?';
                my ( $no, $yes ) = ( '- NO', '- YES' );
                $info = $sf->__print_template_info( \@rows, 8 );
                # Choose
                my $remove_leading_spaces = $tc->choose(
                    [ undef, $no, $yes ],
                    { info => $info, prompt => $prompt, undef => '  ' . $sf->{i}{back}, layout => 3 }
                );
                $ax->print_sql_info( $info );
                if ( ! defined $remove_leading_spaces ) {
                    next COL_WIDTHS;
                }
                my $template = join( ' ', map { 'A' . $_ } @values );
                seek $fh, 0, 0;
                my $rows_of_cols = [];
                if ( $remove_leading_spaces eq $yes ) {
                    while ( my $row = <$fh> ) {
                        push @$rows_of_cols, [ map { s/^\s+//; $_ } unpack( $template, $row ) ];
                    }
                }
                else {
                    while ( my $row = <$fh> ) {
                        push @$rows_of_cols, [ unpack( $template, $row ) ];
                    }
                }
                $sql->{insert_into_args} = $rows_of_cols;
                return 1;
            }
        }
    }
}


sub __parse_with_Spreadsheet_Read {
    my ( $sf, $sql, $file_fs ) = @_;
    my $tc = Term::Choose->new( { %{$sf->{i}{tc_default}}, clear_screen => 1 } );
    $sf->__print_waiting_str;
    require Spreadsheet::Read;
    my $book = $sf->{i}{S_R}{$file_fs}{book};
    if ( ! defined $book ) {
        delete $sf->{i}{S_R};
        $book = Spreadsheet::Read::ReadData( $file_fs, cells => 0, attr => 0, rc => 1, strip => 0 );
        $sf->{i}{S_R}{$file_fs}{book} = $book;
        if ( ! defined $book ) {
            $tc->choose(
                [ 'Press ENTER' ],
                { prompt => 'No Book in ' . decode( 'locale_fs', $file_fs ) . '!' }
            );
            return;
        }
    }
    $sf->{i}{S_R}{$file_fs}{sheet_count} = @$book - 1; # first sheet in $book contains meta info
    my $sheet_count = $sf->{i}{S_R}{$file_fs}{sheet_count};
    if ( $sheet_count == 0 ) {
        $tc->choose(
            [ 'Press ENTER' ],
            { prompt => 'No Sheets in ' . decode( 'locale_fs', $file_fs ) . '!' }
        );
        return;
    }
    my $sheet_idx;
    if ( $sheet_count == 1 ) {
        $sheet_idx = 1;
    }
    else {
        my @sheets = map { '- ' . ( length $book->[$_]{label} ? $book->[$_]{label} : 'sheet_' . $_ ) } 1 .. $#$book;
        my @pre = ( undef );
        my $menu = [ @pre, @sheets ];
        $sf->{i}{S_R}{$file_fs}{old_idx} //= 0;
        my $old_idx = $sf->{i}{S_R}{$file_fs}{old_idx};

        SHEET: while ( 1 ) {
            # Choose
            my $idx = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, prompt => 'Choose a sheet', index => 1, default => $old_idx,
                undef => '  <=' }
            );
            if ( ! defined $idx || ! defined $menu->[$idx] ) {
                return;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $sf->{i}{S_R}{$file_fs}{old_idx} == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx = 0;
                    next SHEET;
                }
                $old_idx = $idx;
                $sf->{i}{S_R}{$file_fs}{old_idx} = $idx;
                # save the last active user chosen idx as the old_idx and not the auto-jumped idx (0)
            }
            $sheet_idx = $idx - @pre + 1;
            last SHEET;
        }
    }
    if ( $book->[$sheet_idx]{maxrow} == 0 ) {
        my $sheet = length $book->[$sheet_idx]{label} ? $book->[$sheet_idx]{label} : 'sheet_' . $_;
        $tc->choose(
            [ 'Press ENTER' ],
            { prompt => $sheet . ': empty sheet!' }
        );
        return 1;
    }
    $sql->{insert_into_args} = [ Spreadsheet::Read::rows( $book->[$sheet_idx] ) ];
    if ( ! -T $file_fs && length $book->[$sheet_idx]{label} ) {
        $sf->{i}{S_R}{$file_fs}{sheet_name} = $book->[$sheet_idx]{label};
    }
    return 1;
}



1;


__END__
