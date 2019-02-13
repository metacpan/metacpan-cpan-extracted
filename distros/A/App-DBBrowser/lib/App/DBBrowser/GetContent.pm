package # hide from PAUSE
App::DBBrowser::GetContent;

use warnings;
use strict;
use 5.008003;

use Cwd                   qw( realpath );
use Encode                qw( encode decode );
use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile );

use List::MoreUtils qw( all uniq );
use Encode::Locale  qw();

use Term::Choose            qw( choose );
use Term::Choose::Constants qw( :screen );
use Term::Choose::Util      qw( choose_a_dir choose_a_number );
use Term::Form              qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::GetContent::Filter;
use App::DBBrowser::GetContent::ParseFile;
use App::DBBrowser::Opt;

use open ':encoding(locale)';


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
        data_dirs => catfile( $info->{app_dir}, 'file_history.json' )
    };
    $sf->{i}{tmp_copy_paste} = catfile $info->{app_dir}, 'Copy_and_Paste_tmp_file.csv';
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


sub __parse_settings_copy_paste {
    my ( $sf, $i ) = @_;
    my @tmp_str;
    if ( $i == 0 ) {
        @tmp_str = ( '  [Text::CSV]' );
        push @tmp_str, '  field_sep  = ' . $sf->{o}{csv}{sep_char};
        push @tmp_str, '  record_sep = ' . $sf->{o}{csv}{eol} if $sf->{o}{csv}{eol};
    }
    elsif ( $i == 1 ) {
        @tmp_str = ( '  [split]' );
        push @tmp_str, '  field_sep     = ' . $sf->{o}{split}{field_sep};
        push @tmp_str, '  field_l_trim  = ' . $sf->{o}{split}{field_l_trim} if $sf->{o}{split}{field_l_trim};
        push @tmp_str, '  field_r_trim  = ' . $sf->{o}{split}{field_r_trim} if $sf->{o}{split}{field_r_trim};
        push @tmp_str, '  record_sep    = ' . $sf->{o}{split}{record_sep};
        push @tmp_str, '  record_l_trim = ' . $sf->{o}{split}{record_l_trim} if $sf->{o}{split}{record_l_trim};
        push @tmp_str, '  record_r_trim = ' . $sf->{o}{split}{record_r_trim} if $sf->{o}{split}{record_r_trim};
    }
    elsif ( $i == 2 ) {
        @tmp_str = (
            '  [Spreadsheet::Read]'
        );
    }
    return join "\n", @tmp_str;
}

sub from_copy_and_paste {
    my ( $sf, $sql ) = @_;
    my $ax  = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $pf = App::DBBrowser::GetContent::ParseFile->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $parse_mode_idx = $sf->{o}{insert}{copy_parse_mode};

    SETTINGS: while ( 1 ) {
        my @tmp_info = (
            'Settings:',
            $sf->__parse_settings_copy_paste( $parse_mode_idx ),
            ' '
        );
        my ( $confirm, $change ) = ( '  Confirm', '  Change' );
        # Choose
        my $choice = choose(
            [ undef, $confirm, $change ],
            { %{$sf->{i}{lyt_v_clear}}, prompt => 'Choose: ', info => join( "\n", @tmp_info ), undef => '  <<' }
        );
        if ( ! defined $choice ) {
            return;
        }
        elsif ( $choice eq $change ) {
            my $opt = App::DBBrowser::Opt->new( $sf->{i}, $sf->{o} );
            $opt->config_insert();
            $parse_mode_idx = $sf->{o}{insert}{copy_parse_mode};
            next SETTINGS;
        }
        else {
            last SETTINGS;
        }
    }
    $ax->print_sql( $sql );
    print "Multi row:\n";
    my $parse_mode = $sf->{o}{insert}{copy_parse_mode};
    my $file_ec = $sf->{i}{tmp_copy_paste};
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
        my $ok;
        if ( $parse_mode_idx == 0 ) {
            $ok = $pf->__parse_file_Text_CSV( $sql, $fh );
        }
        elsif ( $parse_mode_idx == 1 ) {
            $ok = $pf->__parse_file_split( $sql, $fh );
        }
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
    my $ok = $cf->input_filter( $sql, 1 );
    return if ! $ok;
    return 1;
}


sub __parse_settings_file {
    my ( $sf, $i ) = @_;
    my ( $parse_mode, $field_sep, $record_sep );
    if ( $i == 0 ) {
        $parse_mode = 'Text::CSV';
        $field_sep = $sf->{o}{csv}{sep_char};
    }
    elsif ( $i == 1 ) {
        $parse_mode = 'split';
        $field_sep  = $sf->{o}{split}{field_sep};
        $record_sep = $sf->{o}{split}{record_sep};
    }
    elsif ( $i == 2 ) {
        $parse_mode = 'Spreadsheet::Read';
    }
    my $str = "($parse_mode";
    $str .= " - sep[$field_sep]" if defined $field_sep;
    $str .= ")";
    return $str;
}


sub from_file {
    my ( $sf, $sql ) = @_;
    my $pf = App::DBBrowser::GetContent::ParseFile->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );

    DIR: while ( 1 ) {
        my $dir_ec = $sf->__directory();
        if ( ! defined $dir_ec ) {
            return;
        }
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
        my @files = map { '  ' . decode( 'locale_fs', basename $_ ) } @files_ec;
        my $parse_mode_idx = $sf->{o}{insert}{file_parse_mode};
        my $old_idx = 1;

        FILE: while ( 1 ) {
            my $hidden = 'Choose File ' . $sf->__parse_settings_file( $parse_mode_idx );
            my @pre = ( $hidden, undef );
            my $choices = [ @pre, @files ];
            $ENV{TC_RESET_AUTO_UP} = 0;
            # Choose
            my $idx = choose(
                $choices,
                { %{$sf->{i}{lyt_v_clear}}, prompt => '', index => 1, undef => '  <=', default => $old_idx }
            );
            if ( ! defined $idx || ! defined $choices->[$idx] ) {
                next DIR;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx = 1;
                    next FILE;
                }
                else {
                    $old_idx = $idx;
                }
            }
            delete $ENV{TC_RESET_AUTO_UP};
            if ( $choices->[$idx] eq $hidden ) {
                my $opt = App::DBBrowser::Opt->new( $sf->{i}, $sf->{o} );
                $opt->config_insert();
                $parse_mode_idx = $sf->{o}{insert}{file_parse_mode};
                next FILE;
            }
            my $file_ec = $files_ec[$idx-@pre];
            my $fh;
            if ( $sf->{o}{insert}{file_parse_mode} < 2 && -T $file_ec ) {
                open $fh, '<:encoding(' . $sf->{o}{insert}{file_encoding} . ')', $file_ec or die $!;
                my $ok;
                if ( $parse_mode_idx == 0 ) {
                    $ok = $pf->__parse_file_Text_CSV( $sql, $fh );
                }
                elsif ( $parse_mode_idx == 1 ) {
                    $ok = $pf->__parse_file_split( $sql, $fh );
                }
                if ( ! $ok ) {
                    next FILE;
                }
                if ( ! @{$sql->{insert_into_args}} ) {
                    choose( [ 'empty file!' ], { %{$sf->{i}{lyt_m}}, prompt => 'Press ENTER' } );
                    close $fh;
                    next FILE;
                }
                $ok = $cf->input_filter( $sql, 0 );
                if ( ! $ok ) {
                    next FILE;
                }
                $sf->{d}{file_name} = decode( 'locale_fs', $file_ec );
                return 1;
            }
            else {
                my ( $sheet_count, $sheet_idx );
                $sf->{i}{old_sheet_idx} = 0;

                SHEET: while ( 1 ) {
                    $sql->{insert_into_args} = [];
                    $sheet_count = $pf->__parse_file_Spreadsheet_Read( $sql, $file_ec );
                    if ( ! $sheet_count ) {
                        next FILE;
                    }
                    if ( ! @{$sql->{insert_into_args}} ) { #
                        next SHEET if $sheet_count >= 2;
                        next FILE;
                    }
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
}


sub __directory {
    my ( $sf ) = @_;
    if ( ! $sf->{o}{insert}{max_files} ) {
        return $sf->__new_dir_search();
    }
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    $sf->{i}{old_dir_idx} ||= 0;

    DIR: while ( 1 ) {
        my $h_ref = $ax->read_json( $sf->{data_dirs} );
        my @dirs = sort @{$h_ref->{dirs}||[]};
        my $prompt = sprintf "Choose a dir:";
        my @pre = ( undef, '  NEW search' );
        $ENV{TC_RESET_AUTO_UP} = 0;
        # Choose
        my $idx = choose(
            [ @pre, map( '- ' . $_, @dirs ) ],
            { %{$sf->{i}{lyt_v_clear}}, prompt => $prompt, undef => '  <=', index => 1, default => $sf->{i}{old_dir_idx} }
        );
        if ( ! $idx ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $sf->{i}{old_dir_idx} == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $sf->{i}{old_dir_idx} = 0;
                next DIR;
            }
            else {
                $sf->{i}{old_dir_idx} = $idx;
            }
        }
        delete $ENV{TC_RESET_AUTO_UP};
        my $dir_ec;
        if ( $idx == $#pre ) {
            $dir_ec = $sf->__new_dir_search();
            # Choose
            if ( ! defined $dir_ec || ! length $dir_ec ) {
                next DIR;
            }
        }
        else {
            $dir_ec = realpath encode 'locale_fs', $dirs[$idx-@pre];
        }
        $sf->__add_to_history( $dir_ec );
        return $dir_ec;
    }
}


sub __new_dir_search {
    my ( $sf ) = @_;
    my $default_dir = $sf->{i}{tmp_files_dir} || $sf->{i}{home_dir};
    # Choose
    my $dir_ec = choose_a_dir( { dir => $default_dir, mouse => $sf->{o}{table}{mouse}, clear_screen => 1, decoded => 0 } );
    if ( $dir_ec ) {
        $sf->{i}{tmp_files_dir} = decode 'locale_fs', $dir_ec;
    }
    return $dir_ec;
}


sub __add_to_history {
    my ( $sf, $dir_ec ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $h_ref = $ax->read_json( $sf->{data_dirs} ); ###
    my $dirs_ec = [ map { realpath encode( 'locale_fs', $_ ) } @{$h_ref->{dirs}||[]} ];
    unshift @$dirs_ec, $dir_ec;
    @$dirs_ec = uniq @$dirs_ec;
    if ( @$dirs_ec > $sf->{o}{insert}{max_files} ) {
        $#{$dirs_ec} = $sf->{o}{insert}{max_files} - 1;
    }
    $h_ref->{dirs} = [ map { decode( 'locale_fs', $_ ) } @$dirs_ec ];
    $ax->write_json( $sf->{data_dirs}, $h_ref ); ###
}










1;


__END__
