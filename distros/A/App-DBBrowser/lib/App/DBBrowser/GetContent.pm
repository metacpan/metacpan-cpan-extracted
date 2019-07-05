package # hide from PAUSE
App::DBBrowser::GetContent;

use warnings;
use strict;
use 5.010001;

use Cwd                   qw( realpath );
use Encode                qw( encode decode );
use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile );

use List::MoreUtils qw( all uniq );
use Encode::Locale  qw();

use Term::Choose            qw();
use Term::Choose::Constants qw( :screen );
use Term::Choose::Util      qw( choose_a_dir choose_a_number );
use Term::Form              qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::GetContent::Filter;
use App::DBBrowser::GetContent::ParseFile;
use App::DBBrowser::Opt::Set;

use open ':encoding(locale)';


sub new {
    my ( $class, $info, $options, $data ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $data,
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
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $col_names = $sql->{insert_into_cols};
    if ( ! @$col_names ) {
        $sf->__print_args( $sql );
        # Choose a number
        my $col_count = choose_a_number( 3,
            { name => 'Number of columns: ', small_first => 1, mouse => $sf->{o}{table}{mouse}, confirm => 'Confirm',
              back => 'Back', clear_screen => 0, hide_cursor => 0 } #
        );
        if ( ! $col_count ) {
            return;
        }
        $col_names = [ map { 'c' . $_ } 1 .. $col_count ];
        my $col_number = 0;
        my $fields = [ map { [ ++$col_number, defined $_ ? "$_" : '' ] } @$col_names ];
        # Fill_form
        my $form = $tf->fill_form(
            $fields,
            { prompt => 'Col names:', auto_up => 2, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back} . '   ' }
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
            my $col = $tf->readline( $col_name . ': ' );
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
            my $add_row = $tc->choose(
                $choices,
                { %{$sf->{i}{lyt_h}}, prompt => '', default => $default }
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
                    my $idx = $tc->choose(
                        [ 'NO', 'YES'  ],
                        { prompt => 'Discard all entered data?', index => 1 }
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


sub _options_copy_and_paste {
    my $groups = [
        { name => 'group_insert', text => '' }
    ];
    my $options = [
        { name => '_parse_copy',   text => "- Parse Tool",     section => 'insert' },
        { name => '_split_config', text => "- split settings", section => 'split'  },
        { name => '_csv_char',     text => "- CSV settings-a", section => 'csv'    },
        { name => '_csv_options',  text => "- CSV settings-b", section => 'csv'    },
    ];
    return $groups, $options;
}


sub from_copy_and_paste {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $pf = App::DBBrowser::GetContent::ParseFile->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $parse_mode_idx = $sf->{o}{insert}{copy_parse_mode};
    $ax->print_sql( $sql );
    print "Multi row:\n";
    my $file_fs = $sf->{i}{f_copy_paste};
    if ( ! eval {
        open my $fh_in, '>', $file_fs or die $!;
        # STDIN
        while ( my $row = <STDIN> ) {
            print $fh_in $row;
        }
        close $fh_in;
        1 }
    ) {
        $ax->print_error_message( $@, join ', ', @{$sf->{i}{stmt_types}}, 'copy & paste' );
        unlink $file_fs or warn $!;
        return;
    }
    if ( ! -s $file_fs ) {
        $sql->{insert_into_args} = [];
        return;
    }

    PARSE: while ( 1 ) {
        open my $fh, '<', $file_fs or die $!;
        $sql->{insert_into_args} = [];
        my $parse_ok;
        if ( $parse_mode_idx == 0 ) {
            $parse_ok = $pf->__parse_file_Text_CSV( $sql, $fh );
        }
        elsif ( $parse_mode_idx == 1 ) {
            $parse_ok = $pf->__parse_file_split( $sql, $fh );
        }
        close $fh;
        if ( ! $parse_ok ) {
            die "Error __parse_file!";
        };
        if ( all { @$_ == 0 } @{$sql->{insert_into_args}} ) {
            $sql->{insert_into_args} = [];
            return;
        }
        my $filter_ok = $cf->input_filter( $sql, 1 );
        if ( ! $filter_ok ) {
            return;
        }
        elsif ( $filter_ok == -1 ) {
            my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
            $sf->{o} = $opt_set->set_options( _options_copy_and_paste() );
            $parse_mode_idx = $sf->{o}{insert}{copy_parse_mode};
            next PARSE;
        }
        last PARSE;
    }
    unlink $file_fs or die $!;
    return 1;
}


sub __parse_settings_file {
    my ( $sf, $i ) = @_;
    if    ( $i == 0 ) { return '(Text::CSV - sep[' . $sf->{o}{csv}{sep_char}    . '])' }
    elsif ( $i == 1 ) { return '(split - sep['     . $sf->{o}{split}{field_sep} . '])' }
    elsif ( $i == 2 ) { return '(Spreadsheet::Read)'                                   }
}


sub _options_file {
    my ( $all ) = @_;
    my $groups = [
        { name => 'group_insert', text => '' }
    ];
    my $options = [
        { name => '_parse_file',    text => "- Parse Tool",     section => 'insert' },
        { name => '_split_config',  text => "- split settings", section => 'split'  },
        { name => '_csv_char',      text => "- CSV settings-a", section => 'csv'    },
        { name => '_csv_options',   text => "- CSV settings-b", section => 'csv'    },
        { name => '_file_encoding', text => "- File Encoding",  section => 'insert' },
        { name => 'history_dirs',   text => "- Dir History",    section => 'insert' },
    ];
    if ( ! $all ) {
        splice @$options, -2;
    }
    return $groups, $options;
}


sub from_file {
    my ( $sf, $sql ) = @_;
    my $pf = App::DBBrowser::GetContent::ParseFile->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );

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
            # Choose
            my $idx = $tc->choose(
                $choices,
                { %{$sf->{i}{lyt_v_clear}}, prompt => '', index => 1, default => $old_idx, undef => '  <=' }
            );
            if ( ! defined $idx || ! defined $choices->[$idx] ) {
                return if $sf->{o}{insert}{history_dirs} == 1;
                next DIR;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx = 1;
                    next FILE;
                }
                $old_idx = $idx;
            }
            if ( $choices->[$idx] eq $hidden ) {
                my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
                $opt_set->set_options( _options_file( 1 ) );
                $parse_mode_idx = $sf->{o}{insert}{file_parse_mode};
                next FILE;
            }
            my $file_ec = $files_ec[$idx-@pre];

            PARSE: while ( 1 ) {
                if ( $sf->{o}{insert}{file_parse_mode} < 2 && -T $file_ec ) {
                    $sql->{insert_into_args} = [];
                    open my $fh, '<:encoding(' . $sf->{o}{insert}{file_encoding} . ')', $file_ec or die $!;
                    my $parse_ok;
                    if ( $parse_mode_idx == 0 ) {
                        $parse_ok = $pf->__parse_file_Text_CSV( $sql, $fh );
                    }
                    elsif ( $parse_mode_idx == 1 ) {
                        $parse_ok = $pf->__parse_file_split( $sql, $fh );
                    }
                    if ( ! $parse_ok ) {
                        next FILE;
                    }
                    if ( ! @{$sql->{insert_into_args}} ) {
                        $tc->choose(
                            [ 'empty file!' ],
                            { prompt => 'Press ENTER' }
                        );
                        close $fh;
                        next FILE;
                    }
                    my $filter_ok = $cf->input_filter( $sql, 0 );
                    if ( ! $filter_ok ) {
                        next FILE;
                    }
                    elsif ( $filter_ok == -1 ) {
                        my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
                        $sf->{o} = $opt_set->set_options( _options_file() );
                        $parse_mode_idx = $sf->{o}{insert}{file_parse_mode};
                        next PARSE;
                    }
                    $sf->{d}{file_name} = decode( 'locale_fs', $file_ec );
                    return 1;
                }
                else {
                    my $book;
                    $sf->{i}{old_sheet_idx} = 0;

                    SHEET: while ( 1 ) {
                        $sql->{insert_into_args} = [];
                        ( $book, my $sheet_count ) = $pf->__parse_file_Spreadsheet_Read( $sql, $file_ec, $book );
                        if ( ! $sheet_count ) {
                            next FILE;
                        }
                        if ( ! @{$sql->{insert_into_args}} ) { #
                            next SHEET if $sheet_count >= 2;
                            next FILE;
                        }

                        FILTER: while ( 1 ) {
                            my $ok = $cf->input_filter( $sql, 0 );
                            if ( ! $ok ) {
                                next SHEET if $sheet_count >= 2;
                                next FILE;
                            }
                            elsif ( $ok == -1 ) {
                                if ( ! -T $file_ec ) {
                                    $tc->choose(
                                        [ 'Not a text file: "Spreadsheet::Read" used automatically' ],
                                        { prompt => 'Press ENTER' }
                                    );
                                    next FILTER;
                                }
                                my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
                                $sf->{o} = $opt_set->set_options( _options_file() );
                                $parse_mode_idx = $sf->{o}{insert}{file_parse_mode};
                                next PARSE;
                            }
                            last FILTER;
                        }
                        $sf->{d}{file_name} = decode( 'locale_fs', $file_ec );
                        return 1;
                    }
                }
            }
        }
    }
}


sub __directory {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    if ( ! $sf->{o}{insert}{history_dirs} ) {
        return $sf->__new_dir_search();
    }
    elsif ( $sf->{o}{insert}{history_dirs} == 1 ) {
        my $h_ref = $ax->read_json( $sf->{i}{f_dir_history} );
        if ( @{$h_ref->{dirs}||[]} ) {
            return realpath encode 'locale_fs', $h_ref->{dirs}[0];
        }
    }
    $sf->{i}{old_dir_idx} ||= 0;

    DIR: while ( 1 ) {
        my $h_ref = $ax->read_json( $sf->{i}{f_dir_history} );
        my @dirs = sort @{$h_ref->{dirs}||[]};
        my $prompt = sprintf "Choose a dir:";
        my @pre = ( undef, '  NEW search' );
        # Choose
        my $idx = $tc->choose(
            [ @pre, map( '- ' . $_, @dirs ) ],
            { %{$sf->{i}{lyt_v_clear}}, prompt => $prompt, index => 1, default => $sf->{i}{old_dir_idx}, undef => '  <=' }
        );
        if ( ! $idx ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $sf->{i}{old_dir_idx} == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $sf->{i}{old_dir_idx} = 0;
                next DIR;
            }
            $sf->{i}{old_dir_idx} = $idx;
        }
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
    my $dir_ec = choose_a_dir(
        { dir => $default_dir, decoded => 0, mouse => $sf->{o}{table}{mouse}, clear_screen => 1, hide_cursor => 0 }
    );
    if ( $dir_ec ) {
        $sf->{i}{tmp_files_dir} = decode 'locale_fs', $dir_ec;
    }
    return $dir_ec;
}


sub __add_to_history {
    my ( $sf, $dir_ec ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $h_ref = $ax->read_json( $sf->{i}{f_dir_history} );
    my $dirs_ec = [ map { realpath encode( 'locale_fs', $_ ) } @{$h_ref->{dirs}||[]} ];
    unshift @$dirs_ec, $dir_ec;
    @$dirs_ec = uniq @$dirs_ec;
    if ( @$dirs_ec > $sf->{o}{insert}{history_dirs} ) {
        $#{$dirs_ec} = $sf->{o}{insert}{history_dirs} - 1;
    }
    $h_ref->{dirs} = [ map { decode( 'locale_fs', $_ ) } @$dirs_ec ];
    $ax->write_json( $sf->{i}{f_dir_history}, $h_ref );
}










1;


__END__
