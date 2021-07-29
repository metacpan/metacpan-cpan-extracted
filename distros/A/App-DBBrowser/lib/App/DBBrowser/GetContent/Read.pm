package # hide from PAUSE
App::DBBrowser::GetContent::Read;

use warnings;
use strict;
use 5.010001;

use Cwd                   qw( realpath );
use Encode                qw( encode decode );
use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile catdir );

use List::MoreUtils qw( all uniq );
use Encode::Locale  qw();
#use Text::CSV qw();                 # required

use Term::Choose           qw();
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Screen   qw( clear_screen show_cursor hide_cursor );
use Term::Choose::Util     qw( get_term_width );
use Term::Form             qw();

use App::DBBrowser::Auxil;
#use App::DBBrowser::Opt::Set;      # required

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


sub __get_read_info {
    my ( $sf, $aoa ) = @_;
    my $term_w = get_term_width();
    my @tmp = ( 'DATA:' );
    for my $row ( @$aoa ) {
        push @tmp, line_fold( join( ', ', @$row ), $term_w, { subseq_tab => ' ' x 4, join => 0 } );
    }
    return join( "\n", @tmp ) . "\n";
}


sub from_col_by_col {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $aoa = [];
    my $col_names;
    if ( $sf->{i}{stmt_types}[0] eq 'Create_table' ) {
        my $col_count;

        COL_COUNT: while ( 1 ) {
            my $info = 'DATA:';
            # Choose a number
            $col_count = $tu->choose_a_number( 2,
                { info => $info, cs_label => 'Number of columns: ', small_first => 1, confirm => 'Confirm',
                  default_number => $col_count, back => 'Back' }
            );
            $ax->print_sql_info( $info );
            if ( ! $col_count ) {
                return;
            }
            $col_names = [ map { 'c' . $_ } 1 .. $col_count ];
            my $col_number = 0;
            my $fields = [ map { [ ++$col_number, defined $_ ? "$_" : '' ] } @$col_names ];
            # Fill_form
            my $form = $tf->fill_form(
                $fields,
                { info => $info, prompt => 'Col names:', auto_up => 2, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back} . '   ' }
            );
            $ax->print_sql_info( $info );
            if ( ! $form ) {
                next COL_COUNT;
            }
            $col_names = [ map { $_->[1] } @$form ]; # not quoted
            unshift @$aoa, $col_names;
            last COL_COUNT;
        }
    }
    else {
        $col_names = $sql->{insert_into_cols};
    }

    ROWS: while ( 1 ) {
        my $row_idxs = @$aoa;

        COLS: for my $col_name ( @$col_names ) {
            my $info = $sf->__get_read_info( $aoa );
            # Readline
            my $col = $tf->readline(
                $col_name . ': ',
                { info => $info }
            );
            $ax->print_sql_info( $info );
            push @{$aoa->[$row_idxs]}, $col;
        }
        my $default = 0;
        if ( @$aoa ) {
            $default = ( all { ! length } @{$aoa->[-1]} ) ? 3 : 2;
        }

        ASK: while ( 1 ) {
            my ( $add, $del ) = ( 'Add', 'Del' );
            my @pre = ( undef, $sf->{i}{ok} );
            my $menu = [ @pre, $add, $del ];
            my $info = $sf->__get_read_info( $aoa );
            # Choose
            my $add_row = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_h}}, info => $info, prompt => '', default => $default }
            );
            $ax->print_sql_info( $info );
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
                my $file_fs = $sf->{i}{f_plain};
                require Text::CSV;
                Text::CSV::csv( in => $aoa, out => $file_fs ) or die Text::CSV->error_diag;
                return 1, $file_fs;
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
    my $file_fs = $sf->{i}{f_copy_and_paste};
    if ( ! eval {
        open my $fh_in, '>', $file_fs or die $!;
        # STDIN
        while ( my $row = <STDIN> ) {
            print $fh_in $row;
        }
        close $fh_in;
        1 }
    ) {
        print hide_cursor();
        $ax->print_error_message( $@ );
        unlink $file_fs or warn $!;
        return;
    }
    print hide_cursor();
    if ( ! -s $file_fs ) {
        return;
    }
    return 1, $file_fs;
}


sub from_file {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );

    DIR: while ( 1 ) {
        if ( ! @{$sf->{i}{gc}{files_in_chosen_dir}//[]} ) {
            my $dir = $sf->__directory( $sql );
            if ( ! defined $dir ) {
                return;
            }
            $sf->{i}{gc}{files_in_chosen_dir} = $sf->__files_in_dir( $dir );
        }
        $sf->{i}{gc}{old_idx_file} //= 1;

        FILE: while ( 1 ) {
            my $hidden = 'Choose File:';
            my @pre = ( $hidden, undef );
            my $change_dir = '  Change dir';
            if ( $sf->{o}{insert}{history_dirs} == 1 ) {
                push @pre, $change_dir;
            }
            my $menu = [ @pre, map { '  ' . basename $_ } @{$sf->{i}{gc}{files_in_chosen_dir}} ]; #
            # Choose
            my $idx = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, prompt => '', index => 1, default => $sf->{i}{gc}{old_idx_file},
                  undef => '  <=' }
            );
            if ( ! defined $idx || ! defined $menu->[$idx] ) {
                delete $sf->{i}{gc}{files_in_chosen_dir};
                if ( $sf->{o}{insert}{history_dirs} == 1 ) {
                    return;
                }
                next DIR;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $sf->{i}{gc}{old_idx_file} == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $sf->{i}{gc}{old_idx_file} = 1;
                    next FILE;
                }
                $sf->{i}{gc}{old_idx_file} = $idx;
            }
            if ( $menu->[$idx] eq $hidden ) {
                require App::DBBrowser::Opt::Set;
                my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
                say "Settings";
                $opt_set->set_options( [ { name => 'group_insert', text => '' } ] );
                next DIR;
            }
            elsif ( $menu->[$idx] eq $change_dir ) {
                my $dir = $sf->__new_search_dir();
                $sf->{i}{gc}{files_in_chosen_dir} = $sf->__files_in_dir( $dir );
                next FILE;
            }
            my $file_fs = encode( 'locale_fs', $sf->{i}{gc}{files_in_chosen_dir}[$idx-@pre] );
            return 1, $file_fs;
        }
    }
}


sub __files_in_dir {
    my ( $sf, $dir ) = @_;
    my $dir_fs = realpath encode( 'locale_fs', $dir );
    my @tmp_files_fs;
    if ( length $sf->{o}{insert}{file_filter} ) {
        @tmp_files_fs = map { basename $_} grep { -e $_ } glob( catfile( $dir_fs, $sf->{o}{insert}{file_filter} ) );
    }
    else {
        opendir( my $dh, $dir_fs ) or die $!;
        @tmp_files_fs = readdir $dh;
        closedir $dh;
    }
    my $files = [];
    for my $file_fs ( sort @tmp_files_fs ) {
        next if $file_fs =~ /^\./ && ! $sf->{o}{insert}{show_hidden_files};
        next if -d catdir $dir_fs, $file_fs;
        push @$files, decode( 'locale_fs', catfile $dir_fs, $file_fs );
    }
    return $files;
}


sub __directory {
    my ( $sf, $sql ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    if ( ! $sf->{o}{insert}{history_dirs} ) {
        my $dir = $sf->__new_search_dir();
        return $dir;
    }
    if ( $sf->{o}{insert}{history_dirs} == 1 ) {
        my $h_ref = $ax->read_json( $sf->{i}{f_dir_history} ) // {};
        if ( @{$h_ref->{dirs}//[]} ) {
            return $h_ref->{dirs}[0];
        }
    }
    $sf->{i}{gc}{old_idx_dir} //= 0;

    DIR: while ( 1 ) {
        my $h_ref = $ax->read_json( $sf->{i}{f_dir_history} ) // {};
        my @dirs = sort @{$h_ref->{dirs}//[]};
        my $prompt = 'Choose a dir:';
        my $new_search = '  NEW search';
        my @pre = ( undef, $new_search );
        my $menu = [ @pre, map( '- ' . $_, @dirs ) ];
        # Choose
        my $idx = $tc->choose( ##
            $menu,
            { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1, default => $sf->{i}{gc}{old_idx_dir},
              undef => '  <=' }
        );
        if ( ! defined $idx || ! defined $menu->[$idx] ) {
            return;
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $sf->{i}{gc}{old_idx_dir} == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $sf->{i}{gc}{old_idx_dir} = 0;
                next DIR;
            }
            $sf->{i}{gc}{old_idx_dir} = $idx;
        }
        my $dir;
        if ( $menu->[$idx] eq $new_search ) {
            $dir = $sf->__new_search_dir();
            if ( ! defined $dir || ! length $dir ) {
                next DIR;
            }
        }
        else {
            $dir = $dirs[$idx-@pre];
        }
        $sf->__add_to_history( $dir );
        return $dir;
    }
}


sub __add_to_history {
    my ( $sf, $dir ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $h_ref = $ax->read_json( $sf->{i}{f_dir_history} ) // {};
    my $dirs = $h_ref->{dirs};
    unshift @$dirs, $dir;
    @$dirs = uniq @$dirs;
    if ( @$dirs > $sf->{o}{insert}{history_dirs} ) {
        $#{$dirs} = $sf->{o}{insert}{history_dirs} - 1;
    }
    $h_ref->{dirs} = $dirs;
    $ax->write_json( $sf->{i}{f_dir_history}, $h_ref );
}


sub __new_search_dir {
    my ( $sf ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $default_dir = $sf->{i}{tmp_files_dir} // $sf->{i}{home_dir};
    # Choose
    my $dir = $tu->choose_a_directory(
        { init_dir => $default_dir, decoded => 1, clear_screen => 1 }
    );
    if ( $dir ) {
        $sf->{i}{tmp_files_dir} = $dir;
    }
    return $dir;
}




1;


__END__
