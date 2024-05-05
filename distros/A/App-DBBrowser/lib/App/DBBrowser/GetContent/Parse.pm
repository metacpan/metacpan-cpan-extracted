package # hide from PAUSE
App::DBBrowser::GetContent::Parse;

use warnings;
use strict;
use 5.014;

use Encode qw( decode );

use Encode::Locale    qw();
#use Spreadsheet::Read qw( ReadData rows ); # required
#use String::Unescape  qw( unescape );      # required
#use Text::CSV_XS      qw();                # required

use Term::Choose           qw();
use Term::Choose::LineFold qw( line_fold print_columns );
use Term::Choose::Screen   qw( clear_screen );
use Term::Choose::Util     qw( get_term_size get_term_width unicode_sprintf insert_sep );
use Term::Form             qw();

#use App::DBBrowser::Opt::Set;              # required


sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    bless $sf, $class;
}


sub __print_waiting_str {
    my ( $sf ) = @_;
    print clear_screen;
    print 'Parsing file ... ' . "\r";
}


sub parse_with_Text_CSV {
    my ( $sf, $sql, $fh ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    $sf->__print_waiting_str;
    seek $fh, 0, 0;
    my $rows_of_cols = [];
    require String::Unescape;
    my $options = {
        map { $_ => String::Unescape::unescape( $sf->{o}{csv_in}{$_} ) }
        # grep length: keep the default value if the option is set to ''
        grep { length $sf->{o}{csv_in}{$_} }
        keys %{$sf->{o}{csv_in}}
    };
    require Text::CSV_XS;
    my $csv = Text::CSV_XS->new( $options ) or die Text::CSV_XS->error_diag();
    $csv->callbacks( error => sub {
        my ( $code, $str, $pos, $rec, $fld ) = @_;
        if ( $code == 2012 ) {
            # no warnings for end of data.
            # 2012 "EOF - End of data in parsing input stream"
        }
        else {
            my $error_input = $csv->error_input() // 'No Error Input defined.';
            my $prompt = "Error Input:";
            $error_input =~ s/\R/ /g;
            my $info = "Close with ENTER\nText::CSV_XS\n$code $str\nposition:$pos record:$rec field:$fld\n";
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
    $sql->{insert_args} = $rows_of_cols;
    return 1;
}


sub parse_with_split {
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
    $sql->{insert_args} = $rows_of_cols;
    return 1;
}


sub __print_template_info {
    my ( $sf, $rows, $occupied_term_h ) = @_;
    my ( $term_w, $term_h ) = get_term_size();
    my $ten_steps = '';
    for my $count ( 1 .. int( $term_w / 10 ) ) {
        $ten_steps .= ( ' ' x ( 10 - length $count ) ) . $count;
    }
    my $tapeline = '123456789*';
    my $ruler = '';
    $ruler .= $tapeline x int( $term_w / 10 );
    $ruler .= substr( $tapeline, 0, ( $term_w % 10 ) );
    my $info = $ten_steps . "\n" . $ruler;
    my $avail_h = $term_h - $occupied_term_h;
    if ( $avail_h < 5 ) { ##
        $avail_h = 5;
    }
    my $first_part_end = int( $avail_h / 1.5 );
    my $second_part_begin = $avail_h - $first_part_end;
    $first_part_end--;
    $second_part_begin--;
    my $end_idx = $#{$rows};
    my $dots = $sf->{i}{dots};
    my $dots_w = print_columns( $dots );
    if ( @$rows > $avail_h ) {
        for my $row ( @{$rows}[ 0 .. $first_part_end ] ) {
            $info .= "\n" . unicode_sprintf( $row, $term_w, { mark_if_truncated => [ $dots, $dots_w ] } );
        }
        $info .= "\n[...]";
        for my $row ( @{$rows}[ $end_idx - $second_part_begin .. $end_idx ] ) {
            $info .= "\n" . unicode_sprintf( $row, $term_w, { mark_if_truncated => [ $dots, $dots_w ] } );
        }
        my $row_count = scalar( @$rows );
        $info .= "\n" . unicode_sprintf( '[' . insert_sep( $row_count, $sf->{i}{info_thsd_sep} ) . ' rows]', $term_w, { mark_if_truncated => [ $dots, $dots_w ] } );
    }
    else {
        for my $row ( @$rows ) {
            $info .= "\n" . unicode_sprintf( $row, $term_w, { mark_if_truncated => [ $dots, $dots_w ] } );
        }
    }
    $info .= "\n";
    return $info;
}


sub parse_with_template {
    my ( $sf, $sql, $fh ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $old_idx = 0;

    IRS: while ( 1 ) {
        my $prompt = 'Choose the input record separator:';
        my @irs = ( "\\n", "\\r", "\\r\\n" );
        my $reparse = '  Reparse';
        my @pre = ( undef );
        my $menu = [ @pre, map( '  "' . $_ . '"', @irs ), $reparse ];
        my $info = "Parse mode: Template\n";
        # Choose
        my $idx = $tc->choose(
            $menu,
            { prompt => $prompt, index => 1, default => $old_idx, layout => 2, undef => '  <=', clear_screen => 1, info => $info }
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
            my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
            $sf->{o} = $opt_set->set_options( 'import' );
            return -1;
        }
        require String::Unescape;
        $/ = String::Unescape::unescape( $irs[$idx-@pre] );
        $sf->__print_waiting_str;
        seek $fh, 0, 0;
        my @rows = grep { ! /^\s+\z/ } <$fh>;
        chomp @rows;
        my $fields_set = [ [ 'Col count', ], [ 'Sep width', ], ];

        SETTINGS: while ( 1 ) {
            my $info = $sf->__print_template_info( \@rows, 7 + @$fields_set );
            # Fill_form
            my $form_set = $tf->fill_form(
                $fields_set,
                { info => $info, prompt => 'Settings:', confirm => $sf->{i}{confirm}, back => $sf->{i}{back} . '   ' }
            );
            $ax->print_sql_info( $info );
            if ( ! $form_set ) {
                next IRS;
            }
            my $number_of_columns = $form_set->[0];
            my $separator_width = $form_set->[1];
            my $prompt;
            if ( ! defined $number_of_columns->[1] || $number_of_columns->[1] !~ /^[1-9][0-9]*\z/ ) { ## defined
                $prompt = "'$number_of_columns->[0]' requires a value of 1 or greater!";
            }
            if ( ! length $separator_width->[1] ) {
                $separator_width->[1] = 0;
            }
            if ( $separator_width->[1] !~ /^(?:0|[1-9][0-9]*)\z/ ) {
                $prompt = "'$separator_width->[0]' requires a value of 0 or greater!";
            }
            if ( $prompt ) {
                my $info = $sf->__print_template_info( \@rows, 6 );
                $tc->choose(
                    [ 'Press ENTER' ],
                    { info => $info, prompt => $prompt }
                );
                $ax->print_sql_info( $info );
                @$fields_set = @$form_set;
                next SETTINGS;
            }
            my $col_count = $number_of_columns->[1];
            my $col_sep_w = $separator_width->[1];
            my $col_names = [ map { 'c' . $_ } 1 .. $col_count ];
            my $fields = [ map { [ $_, ] } @$col_names ];
            $fields->[-1][1] = '*';

            COL_WIDTHS: while ( 1 ) {
                my $info = $sf->__print_template_info( \@rows, 7 + $col_count );
                my $prompt = 'Separator width: ' . $col_sep_w;
                $prompt .= "\n". 'Column widths:';
                # Fill_form
                my $form = $tf->fill_form(
                    $fields,
                    { info => $info, prompt => $prompt, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back} . '   ' }
                );
                $ax->print_sql_info( $info );
                if ( ! $form ) {
                    @$fields_set = @$form_set;
                    next SETTINGS;
                }
                my @values;
                for my $field ( @$form ) {
                    my ( $field_name, $field_value ) = @$field;
                    my ( $valid_regex, $error_message );
                    if ( $field_name eq $form->[-1][0] ) {
                        $valid_regex = qr/^(?:\*|[1-9][0-9]*)\z/;
                        $error_message = " requires * or a value of 1 or greater!";
                    }
                    else {
                        $valid_regex = qr/^[1-9][0-9]*\z/;
                        $error_message = " requires a value of 1 or greater!";
                    }
                    if ( ! defined $field_value || $field_value !~ $valid_regex ) { ## defined
                        $prompt = "'$field_name' " . $error_message;
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
                $prompt = 'Remove leading spaces?';
                my ( $no, $yes ) = ( '- NO', '- YES' );
                $info = $sf->__print_template_info( \@rows, 8 );
                # Choose
                my $remove_leading_spaces = $tc->choose(
                    [ undef, $no, $yes ],
                    { info => $info, prompt => $prompt, undef => '  ' . $sf->{i}{back}, layout => 2 }
                );
                $ax->print_sql_info( $info );
                if ( ! defined $remove_leading_spaces ) {
                    next COL_WIDTHS;
                }
                my $template = join( 'x' x $col_sep_w, map { 'A' . $_ } @values );
                my $rows_of_cols = [];
                if ( ! eval {
                    seek $fh, 0, 0;
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
                    1 }
                ) {
                    $ax->print_error_message( $@ );
                    @$fields = @$form;
                    next COL_WIDTHS;
                }
                $sql->{insert_args} = $rows_of_cols;
                return 1;
            }
        }
    }
}


sub parse_with_Spreadsheet_Read {
    my ( $sf, $sql, $source, $file_fs ) = @_;
    my $tc = Term::Choose->new( { %{$sf->{i}{tc_default}}, clear_screen => 1 } );
    $sf->__print_waiting_str;
    require Spreadsheet::Read;
    my $book = delete $source->{saved_book};
    if ( ! defined $book ) {
        if ( ! eval {
            $book = Spreadsheet::Read::ReadData( $file_fs, cells => 0, attr => 0, rc => 1, strip => 0 );
            1 }
        ) {
            die "Read::Spreadsheet: $@";
        }
        if ( ! defined $book ) {
            $tc->choose(
                [ 'Press ENTER' ],
                { prompt => 'No Book in ' . decode( 'locale_fs', $file_fs ) . '!' }
            );
            return;
        }
    }
    my $sheet_count = @$book - 1; # first sheet in $book contains meta info
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
        $source->{saved_book} = $book; # save book if more than one sheet
        my @sheets = map { '- ' . ( length $book->[$_]{label} ? $book->[$_]{label} : 'sheet_' . $_ ) } 1 .. $#$book;
        my @pre = ( undef );
        my $menu = [ @pre, @sheets ];

        SHEET: while ( 1 ) {
            # Choose
            my $idx = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, prompt => 'Choose a sheet', index => 1, default => $source->{old_idx_sheet},
                undef => '  <=' }
            );
            if ( ! defined $idx || ! defined $menu->[$idx] ) {
                return;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $source->{old_idx_sheet} == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $source->{old_idx_sheet} = 0;
                    next SHEET;
                }
                $source->{old_idx_sheet} = $idx;
            }
            $sheet_idx = $idx - @pre + 1;
            last SHEET;
        }
    }
#    if ( $book->[$sheet_idx]{maxrow} == 0 ) { # works for some file formats; catch empty sheets later ##
#        my $sheet = length $book->[$sheet_idx]{label} ? $book->[$sheet_idx]{label} : 'sheet_' . $_;
#        $tc->choose(
#            [ 'Press ENTER' ],
#            { prompt => $sheet . ': Empty Sheet!' }
#        );
#        return 1;
#    }
    $sql->{insert_args} = [ Spreadsheet::Read::rows( $book->[$sheet_idx] ) ];
    if ( ! -T $file_fs && length $book->[$sheet_idx]{label} ) {
        $source->{sheet_name} = $book->[$sheet_idx]{label};
    }
    return 1;
}




1;


__END__
