package # hide from PAUSE
App::DBBrowser::GetContent::Read;

use warnings;
use strict;
use 5.010001;

use Cwd                   qw( realpath );
use Encode                qw( encode decode );
use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile );

use List::MoreUtils qw( all uniq );
use Encode::Locale  qw();

use Term::Choose           qw();
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Screen   qw( clear_screen show_cursor hide_cursor );
use Term::Choose::Util     qw( get_term_width );
use Term::Form             qw();

use App::DBBrowser::Auxil;

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
    my ( $sf, $aoa ) = @_;
    my $term_w = get_term_width();
    my @tmp = ( 'Table Data:' );
    for my $row ( @$aoa ) {
        push @tmp, line_fold( join( ', ', @$row ), $term_w, { subseq_tab => ' ' x 4 } );
    }
    my $str = join( "\n", @tmp ) . "\n\n";
    print clear_screen();
    print $str;
}


sub from_col_by_col {
    my ( $sf, $sql ) = @_;
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $aoa = [];
    my $col_names = $sql->{insert_into_cols};
    if ( ! @$col_names ) {
        $sf->__print_args( $aoa );
        # Choose a number
        my $col_count = $tu->choose_a_number( 2,
            { current_selection_label => 'Number of columns: ', small_first => 1, confirm => 'Confirm', back => 'Back' }
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
        unshift @$aoa, $col_names;
    }

    ROWS: while ( 1 ) {
        my $row_idxs = @$aoa;

        COLS: for my $col_name ( @$col_names ) {
            $sf->__print_args( $aoa );
            # Readline
            my $col = $tf->readline( $col_name . ': ' );
            push @{$aoa->[$row_idxs]}, $col;
        }
        my $default = 0;
        if ( @$aoa ) {
            $default = ( all { ! length } @{$aoa->[-1]} ) ? 3 : 2;
        }

        ASK: while ( 1 ) {
            $sf->__print_args( $aoa );
            my ( $add, $del ) = ( 'Add', 'Del' );
            my @pre = ( undef, $sf->{i}{ok} );
            my $choices = [ @pre, $add, $del ];
            # Choose
            my $add_row = $tc->choose(
                $choices,
                { %{$sf->{i}{lyt_h}}, prompt => '', default => $default }
            );
            if ( ! defined $add_row ) {
                if ( @$aoa ) {
                    $aoa = [];
                    next ASK;
                }
                $aoa = [];
                return;
            }
            elsif ( $add_row eq $sf->{i}{ok} ) {
                if ( ! @$aoa ) {
                    return;
                }
                return 1, $aoa;
            }
            elsif ( $add_row eq $del ) {
                if ( ! @$aoa ) {
                    return;
                }
                $default = 0;
                $#$aoa--;
                next ASK;
            }
            last ASK;
        }
    }
}


sub from_copy_and_paste {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    print clear_screen();
    print show_cursor();
    print "Paste multi-row:  (then press Ctrl-D)\n";
    my $file_ec = $sf->{i}{f_copy_paste};
    if ( ! eval {
        open my $fh_in, '>', $file_ec or die $!;
        # STDIN
        while ( my $row = <STDIN> ) {
            print $fh_in $row;
        }
        close $fh_in;
        1 }
    ) {
        print hide_cursor();
        $ax->print_error_message( $@, join ', ', @{$sf->{i}{stmt_types}}, 'copy & paste' );
        unlink $file_ec or warn $!;
        return;
    }
    print hide_cursor();
    if ( ! -s $file_ec ) {
        return;
    }
    return 1, $file_ec;
}


sub __parse_settings {
    my ( $sf, $i ) = @_;
    if    ( $i == 0 ) { return '(Text::CSV - sep[' . $sf->{o}{csv}{sep_char}    . '])' }
    elsif ( $i == 1 ) { return '(split - sep['     . $sf->{o}{split}{field_sep} . '])' }
    elsif ( $i == 2 ) { return '(Template)'                                            }
    elsif ( $i == 3 ) { return '(Spreadsheet::Read)'                                   }
}


sub from_file {
    my ( $sf, $sql ) = @_;
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
        my $parse_mode_idx = $sf->{o}{insert}{parse_mode_input_file};
        $sf->{i}{gc}{old_file_idx} //= 1;

        FILE: while ( 1 ) {
            my $hidden = 'Choose File:';
            my @pre = ( $hidden, undef );
            my $choices = [ @pre, @files ];
            # Choose
            my $idx = $tc->choose(
                $choices,
                { %{$sf->{i}{lyt_v_clear}}, prompt => '', index => 1, default => $sf->{i}{gc}{old_file_idx}, undef => '  <=' }
            );
            if ( ! defined $idx || ! defined $choices->[$idx] ) {
                return if $sf->{o}{insert}{history_dirs} == 1;
                next DIR;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $sf->{i}{gc}{old_file_idx} == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $sf->{i}{gc}{old_file_idx} = 1;
                    next FILE;
                }
                $sf->{i}{gc}{old_file_idx} = $idx;
            }
            if ( $choices->[$idx] eq $hidden ) {
                say "Hallo, World!";
                sleep 4;
            }
            my $file_ec = $files_ec[$idx-@pre];
            return 1, $file_ec;
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
    $sf->{i}{gc}{old_dir_idx} //= 0;

    DIR: while ( 1 ) {
        my $h_ref = $ax->read_json( $sf->{i}{f_dir_history} );
        my @dirs = sort @{$h_ref->{dirs}||[]};
        my $prompt = sprintf "Choose a dir:";
        my @pre = ( undef, '  NEW search' );
        # Choose
        my $idx = $tc->choose(
            [ @pre, map( '- ' . $_, @dirs ) ],
            { %{$sf->{i}{lyt_v_clear}}, prompt => $prompt, index => 1, default => $sf->{i}{gc}{old_dir_idx}, undef => '  <=' }
        );
        if ( ! $idx ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $sf->{i}{gc}{old_dir_idx} == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $sf->{i}{gc}{old_dir_idx} = 0;
                next DIR;
            }
            $sf->{i}{gc}{old_dir_idx} = $idx;
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
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $default_dir = $sf->{i}{tmp_files_dir} || $sf->{i}{home_dir};
    # Choose
    my $dir_ec = $tu->choose_a_directory(
        { init_dir => $default_dir, decoded => 0, clear_screen => 1 }
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
