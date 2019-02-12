package # hide from PAUSE
App::DBBrowser::GetContent;

use warnings;
use strict;
use 5.008003;

use Cwd                   qw( realpath );
use Encode                qw( encode decode );
use File::Basename        qw( dirname basename );
use File::Spec::Functions qw( catfile );

use List::MoreUtils   qw( all any first_index uniq );
use Encode::Locale    qw();
#use Spreadsheet::Read qw( ReadData rows ); # required
#use String::Unescape  qw( unescape );      # required
#use Text::CSV         qw();                # required

use Term::Choose            qw( choose );
use Term::Choose::Constants qw( :screen );
use Term::Choose::Util      qw( choose_a_file choose_a_subset choose_a_number insert_sep );
use Term::Form              qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::GetContent::Filter;
use App::DBBrowser::Opt;

use open ':encoding(locale)';


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
        tmp_copy_paste => catfile( $info->{app_dir}, 'Copy_and_Paste_tmp_file.csv' ),
        input_files    => catfile( $info->{app_dir}, 'file_history.json' )
    };
    bless $sf, $class;
}


sub __print_args {
    my ( $sf, $sql ) = @_;
    if ( @{$sf->{i}{stmt_types}} == 1 ) {
        my $ax  = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
        $ax->print_sql( $sql );
    }
    else {
        my $max = 9;
        my @tmp = ( 'Table Data:' );
        my $ax  = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
        my $arg_rows = $ax->insert_into_args_info_format( $sql, '' );
        push @tmp, @$arg_rows;
        my $str = join( "\n", @tmp ) . "\n\n";
        print CLEAR_SCREEN;
        print $str;
    }
}


sub from_col_by_col {
    my ( $sf, $sql ) = @_;
    $sql->{insert_into_args} = [];
    my $trs = Term::Form->new();
    my $col_names = $sql->{insert_into_cols};
    if ( ! @$col_names ) {
        $sf->__print_args( $sql );
        # Choose a number
        my $col_count = choose_a_number( 3,
            { small_on_top => 1, confirm => 'Confirm', mouse => $sf->{o}{table}{mouse},
            back => 'Back', name => 'Number of columns: ', clear_screen => 0 }
        );
        if ( ! $col_count ) {
            return;
        }
        $col_names = [ map { 'c' . $_ } 1 .. $col_count ];
        my $col_number = 0;
        my $fields = [ map { [ ++$col_number, defined $_ ? "$_" : '' ] } @$col_names ];
        # Fill_form
        my $form = $trs->fill_form(
            $fields,
            { prompt => 'Col names:', auto_up => 2, confirm => '  CONFIRM', back => '  BACK   ' }
        );
        if ( ! $form ) {
            return;
        }
        $col_names = [ map { $_->[1] } @$form ]; # not quoted
        unshift @{$sql->{insert_into_args}}, $col_names;
    }

    ROWS: while ( 1 ) {
        my $row_idxs = @{$sql->{insert_into_args}};

        COLS: for my $col_name ( @$col_names ) {
            $sf->__print_args( $sql );
            # Readline
            my $col = $trs->readline( $col_name . ': ' );
            push @{$sql->{insert_into_args}->[$row_idxs]}, $col;
        }
        my $default = 0;
        if ( @{$sql->{insert_into_args}} ) {
            $default = ( all { ! length } @{$sql->{insert_into_args}[-1]} ) ? 3 : 2;
        }

        ASK: while ( 1 ) {
            $sf->__print_args( $sql );
            my ( $add, $del ) = ( 'Add', 'Del' );
            my @pre = ( undef, $sf->{i}{ok} );
            my $choices = [ @pre, $add, $del ];
            # Choose
            my $add_row = choose(
                $choices,
                { %{$sf->{i}{lyt_stmt_h}}, prompt => '', default => $default }
            );
            if ( ! defined $add_row ) {
                if ( @{$sql->{insert_into_args}} ) {
                    $sql->{insert_into_args} = [];
                    next ASK;
                }
                $sql->{insert_into_args} = [];
                return;
            }
            elsif ( $add_row eq $sf->{i}{ok} ) {
                if ( ! @{$sql->{insert_into_args}} ) {
                    return;
                }
                my $bu = [ @{$sql->{insert_into_args}} ];
                my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
                my $ok = $cf->input_filter( $sql, 1 );
                if ( ! $ok ) {
                    # Choose
                    my $idx = choose(
                        [ 'NO', 'YES'  ],
                        { %{$sf->{i}{lyt_m}}, index => 1, prompt => 'Discard all entered data?' }
                    );
                    if ( $idx ) {
                        $sql->{insert_into_args} = [];
                        return;
                    }
                    $sql->{insert_into_args} = $bu;
                };
                return 1;
            }
            elsif ( $add_row eq $del ) {
                if ( ! @{$sql->{insert_into_args}} ) {
                    return;
                }
                $default = 0;
                $#{$sql->{insert_into_args}}--;
                next ASK;
            }
            last ASK;
        }
    }
}


sub from_copy_and_paste {
    my ( $sf, $sql ) = @_;
    my $ax  = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql );
    my $prompt = sprintf "Multi row  %s:\n", $sf->__parse_setting( 'copy_and_paste' );
    print $prompt;
    my $file_ec = $sf->{tmp_copy_paste};
    local $SIG{INT} = sub { unlink $file_ec; exit };
    if ( ! eval {
        open my $fh_in, '>', $file_ec or die $!;
        # STDIN
        while ( my $row = <STDIN> ) {
            print $fh_in $row;
        }
        close $fh_in;
        die "No input!" if ! -s $file_ec;
        open my $fh, '<', $file_ec or die $!;
        $sql->{insert_into_args} = [];
        my $ok = $sf->__parse_file( $sql, $file_ec, $fh, $sf->{o}{insert}{copy_parse_mode} );
        close $fh;
        unlink $file_ec or die $!;
        die "Error __parse_file!" if ! $ok;
        1 }
    ) {
        $ax->print_error_message( $@, join ', ', @{$sf->{i}{stmt_types}}, 'copy & paste' );
        unlink $file_ec or warn $!;
        return;
    }
    return if ! @{$sql->{insert_into_args}};
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $ok = $cf->input_filter( $sql, 1 );
    return if ! $ok;
    return 1;
}


sub from_file {
    my ( $sf, $sql ) = @_;

    FILE: while ( 1 ) {
        my $file_ec = $sf->__file_name();
        my $fh;
        if ( ! defined $file_ec ) {
            return;
        }
        if ( $sf->{o}{insert}{file_parse_mode} < 2 && -T $file_ec ) {
            open $fh, '<:encoding(' . $sf->{o}{insert}{file_encoding} . ')', $file_ec or die $!;
            my $parse_mode = $sf->{o}{insert}{file_parse_mode};
            my $ok = $sf->__parse_file( $sql, $file_ec, $fh, $parse_mode );
            if ( ! $ok ) {
                next FILE;
            }
            if ( ! @{$sql->{insert_into_args}} ) {
                choose( [ 'empty file!' ], { %{$sf->{i}{lyt_m}}, prompt => 'Press ENTER' } );
                close $fh;
                next FILE;
            }
            my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
            $ok = $cf->input_filter( $sql, 0 );
            if ( ! $ok ) {
                next FILE;
            }
            $sf->{d}{file_name} = decode( 'locale_fs', $file_ec );
            return 1;
        }
        else {
            my $parse_mode = 2;
            my ( $sheet_count, $sheet_idx );
            SHEET: while ( 1 ) {
                $sql->{insert_into_args} = [];
                $sheet_count = $sf->__parse_file( $sql, $file_ec, $fh, $parse_mode );
                if ( ! $sheet_count ) {
                    next FILE;
                }
                if ( ! @{$sql->{insert_into_args}} ) { #
                    next SHEET if $sheet_count >= 2;
                    next FILE;
                }
                my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
                my $ok = $cf->input_filter( $sql, 0 );
                if ( ! $ok ) {
                    next SHEET if $sheet_count >= 2;
                    next FILE;
                }
                $sf->{d}{file_name} = decode( 'locale_fs', $file_ec );
                return 1;
            }
        }
    }
}


sub __file_name {
    my ( $sf ) = @_;
    if ( ! $sf->{o}{insert}{max_files} ) {
        return $sf->__new_file_search();
    }
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $old_idx = 0;

    FILE: while ( 1 ) {
        my $h_ref = $ax->read_json( $sf->{input_files} );
        my @dirs = sort @{$h_ref->{dirs}||[]};
        my @files = sort @{$h_ref->{files}||[]};
        my $prompt = sprintf "Choose a file  %s:", $sf->__parse_setting( 'file' );
        my @pre = ( undef, '  NEW search' );
        $ENV{TC_RESET_AUTO_UP} = 0;
        # Choose
        my $idx = choose(
            [ @pre, map( '- ' . $_, @dirs ), map( '  ' . basename( $_ ), @files ) ],
            { %{$sf->{i}{lyt_v_clear}}, prompt => $prompt, undef => '  <=', index => 1, default => $old_idx }
        );
        if ( ! $idx ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $old_idx = 0;
                next DATABASE;
            }
            else {
                $old_idx = $idx;
            }
        }
        delete $ENV{TC_RESET_AUTO_UP};
        my $file_ec;
        if ( $idx == $#pre ) {
            $file_ec = $sf->__new_file_search();
        }
        elsif ( $idx < @pre + @dirs ) {
            my $dir_ec = realpath encode 'locale_fs', $dirs[$idx-@pre];
            $file_ec = $sf->__file_form_history_dir( $dir_ec );
        }
        else {
            $file_ec = realpath encode 'locale_fs', $files[$idx-(@pre+@dirs)];
        }
        if ( ! defined $file_ec || ! length $file_ec ) {
            next FILE;
        }
        $sf->__add_to_history( $file_ec );
        return $file_ec;
    }
}

sub __new_file_search {
    my ( $sf ) = @_;
    my $prompt = sprintf "%s", $sf->__parse_setting( 'file' );
    my $dir = $sf->{i}{tmp_files_dir} || $sf->{i}{home_dir};
    # Choose_a_file
    my $file = choose_a_file( { dir => $dir, mouse => $sf->{o}{table}{mouse}, clear_screen => 1 } );
    if ( ! defined $file || ! length $file ) {
        return;
    }
    my $file_ec = encode( 'locale_fs', $file );
    my $dir_ec  = dirname $file_ec;
    $sf->{i}{tmp_files_dir} = $dir_ec;
    return $file_ec;
}

sub __file_form_history_dir {
    my ( $sf, $dir_ec ) = @_;
    opendir my $dir_h, $dir_ec or die "$dir_ec: $!";

    my @files_ec;
    while ( my $file_ec = readdir( $dir_h ) ) {
        next if $file_ec =~ m/^\./;
        $file_ec = catfile $dir_ec, $file_ec;
        next if ! -f $file_ec;
        push @files_ec, $file_ec;
    }
    close $dir_h;
    @files_ec = sort @files_ec;
    my @choices = map { '  ' . decode( 'locale_fs', basename $_ ) } @files_ec;
    my @pre = ( undef );
    # Choose
    my $idx = choose(
        [ @pre, @choices ],
        { %{$sf->{i}{lyt_v_clear}}, prompt => 'Choose:', undef => '  <=', index => 1,
          info => decode( 'locale_fs', $dir_ec ) }
    );
    if ( ! $idx ) {
        return;
    }
    my $file_ec = $files_ec[$idx-@pre];
    return $file_ec;
}

sub __add_to_history {
    my ( $sf, $file_ec ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $h_ref = $ax->read_json( $sf->{input_files} );
    my %tmp = ( 'files' => $file_ec, 'dirs' => dirname $file_ec );
    for my $key ( keys %tmp ) {
        my $files_ec = [ map { realpath encode( 'locale_fs', $_ ) } @{$h_ref->{$key}||[]} ];
        unshift @$files_ec, $tmp{$key};
        @$files_ec = uniq @$files_ec;
        if ( @$files_ec > $sf->{o}{insert}{max_files} ) {
            $#{$files_ec} = $sf->{o}{insert}{max_files} - 1;
        }
        $h_ref->{$key} = [ map { decode( 'locale_fs', $_ ) } @$files_ec ];
    }
    $ax->write_json( $sf->{input_files}, $h_ref );
}


sub __parse_setting {
    my ( $sf, $type ) = @_;
    my $i = $sf->{o}{insert}{$type eq 'file' ? 'file_parse_mode' : 'copy_parse_mode'};
    my $parse_mode = ( 'Text::CSV', 'split', 'Spreadsheet::Read' )[$i]; #
    my $sep;
    if ( $i == 0 ) {
        $sep = $sf->{o}{csv}{sep_char};
    }
    elsif ( $i == 1 ) {
        $sep = $sf->{o}{split}{field_sep};
    }
    my $str = "($parse_mode";
    $str .= " - sep[$sep]" if defined $sep;
    $str .= ")";
    return $str;
}


sub __parse_file {
    my ( $sf, $sql, $file_ec, $fh, $parse_mode ) = @_;
    local $SIG{INT} = sub { unlink $sf->{tmp_copy_paste}; exit };
    my $waiting = 'Parsing file ... ';
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $ax->print_sql( $sql, $waiting );
    if ( $parse_mode == 0 ) {
        seek $fh, 0, 0;
        my $rows_of_cols = [];
        require Text::CSV;
        require String::Unescape;
        my $options = { map { $_ => String::Unescape::unescape( $sf->{o}{csv}{$_} ) } keys %{$sf->{o}{csv}} };
        my $csv = Text::CSV->new( $options ) or die Text::CSV->error_diag();
        $csv->callbacks( error => sub {
            my ( $code, $str, $pos, $rec, $fld ) = @_;
            if ( $code == 2012 ) { # ignore this error
                Text::CSV->SetDiag (0);
            }
            else {
                my $error_inpunt = $csv->error_input();
                my $message =  "Text::CSV:\n";
                $message .= "Input: $error_inpunt" if defined $error_inpunt;
                $message .= "$code $str - pos:$pos rec:$rec fld:$fld";
                die $message; ###
            }
        } );
        while ( my $cols = $csv->getline( $fh ) ) {
            push @$rows_of_cols, $cols;
        }
        $sql->{insert_into_args} = $rows_of_cols;
        $ax->print_sql( $sql, $waiting );
        return 1;
    }
    elsif ( $parse_mode == 1 ) {
        my $rows_of_cols = [];
        local $/;
        seek $fh, 0, 0;
        my $record_lead  = $sf->{o}{split}{record_l_trim};
        my $record_trail = $sf->{o}{split}{record_r_trim};
        my $field_lead  = $sf->{o}{split}{field_l_trim};
        my $field_trail = $sf->{o}{split}{field_r_trim};
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
        $ax->print_sql( $sql, $waiting );
        return 1;
    }
    else {
        require Spreadsheet::Read;
        $ax->print_sql( $sql, $waiting );
        my $cm = Term::Choose->new( $sf->{i}{lyt_m} );
        my $book = Spreadsheet::Read::ReadData( $file_ec, cells => 0, attr => 0, rc => 1, strip => 0 );
        if ( ! defined $book ) {
            $cm->choose( [ 'Press ENTER' ], { prompt => 'No Book in ' . decode( 'locale_fs', $file_ec ) .'!' } );
            return;
        }
        my $sheet_count = @$book - 1; # first sheet in $book contains meta info
        if ( $sheet_count == 0 ) {
            $cm->choose( [ 'Press ENTER' ], { prompt => 'No Sheets in ' . decode( 'locale_fs', $file_ec ) . '!' } );
            return;
        }
        my $sheet_idx;
        if ( $sheet_count == 1 ) {
            $sheet_idx = 1;
        }
        else {
            my @sheets = map { '- ' . ( length $book->[$_]{label} ? $book->[$_]{label} : 'sheet_' . $_ ) } 1 .. $#$book;
            my @pre = ( undef );
            my $choices = [ @pre, @sheets ];
            # Choose
            $sheet_idx = choose( # m
                $choices,
                { %{$sf->{i}{lyt_stmt_v}}, index => 1, prompt => 'Choose a sheet' }
            );
            if ( ! defined $sheet_idx || ! defined $choices->[$sheet_idx] ) {
                return;
            }
            $sheet_idx = $sheet_idx - @pre + 1;
        }
        if ( $book->[$sheet_idx]{maxrow} == 0 ) {
            my $sheet = length $book->[$sheet_idx]{label} ? $book->[$sheet_idx]{label} : 'sheet_' . $_;
            $cm->choose( [ 'Press ENTER' ], { prompt => $sheet . ': empty sheet!' } );
            return $sheet_count;
        }
        $sql->{insert_into_args} = [ Spreadsheet::Read::rows( $book->[$sheet_idx] ) ];
        if ( ! -T $file_ec && length $book->[$sheet_idx]{label} ){
            $sf->{d}{sheet_name} = $book->[$sheet_idx]{label};
        }
        return $sheet_count;
    }
}





1;


__END__
