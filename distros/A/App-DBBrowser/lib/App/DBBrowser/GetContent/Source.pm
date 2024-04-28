package # hide from PAUSE
App::DBBrowser::GetContent::Source;

use warnings;
use strict;
use 5.014;

use Cwd                   qw( realpath );
use Encode                qw( encode decode );
use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile catdir );

use List::MoreUtils qw( uniq firstidx );
use Encode::Locale  qw();

use Term::Choose           qw();
use Term::Choose::LineFold qw( line_fold );
use Term::Choose::Util     qw( get_term_width );
use Term::Form             qw();

use App::DBBrowser::Auxil;
#use App::DBBrowser::Opt::Set;      # required



sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    bless $sf, $class;
}


sub __get_read_info {
    my ( $sf, $aoa ) = @_;
    my $term_w = get_term_width();
    my @tmp = ( 'DATA:' );
    for my $row ( @$aoa ) {
        no warnings 'uninitialized';
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
    my $back = 'Back';
    my $confirm = 'Confirm';
    my $stmt_type = $sf->{d}{stmt_types}[0];

    COL_BY_COL: while( 1 ) {
        my $aoa = [];
        my $col_names;
        if ( $stmt_type eq 'Create_Table' ) {
            my $col_count;
            my $info = 'CREATE TABLE';

            COL_COUNT: while ( 1 ) {
                # Choose a number
                $col_count = $tu->choose_a_number( 2,
                    { info => $info, cs_label => 'Number of columns: ', small_first => 1, confirm => $confirm,
                    default_number => $col_count, back => $back, prompt => '' }
                );
                if ( ! $col_count ) {
                    return;
                }
                my $fields = [ map { [ $_, '' ] } 1 .. $col_count ];
                # Fill_form
                my $form = $tf->fill_form(
                    $fields,
                    { info => $info, prompt => 'Column names:', confirm => $confirm, back => $back . '   ' }
                );
                if ( ! $form ) {
                    next COL_COUNT;
                }
                $col_names = [ map { $_->[1] } @$form ]; # not quoted
                unshift @$aoa, $col_names;
                last COL_COUNT;
            }
        }
        else {
            $col_names = $sql->{insert_col_names};
        }
        my $default;

        WHAT_NEXT: while ( 1 ) {
            my $add = 'Add Data';
            my @pre = ( undef, $sf->{i}{ok} );
            my $menu = [ @pre, $add ];
            my $info = $sf->__get_read_info( $aoa );
            # Choose
            my $choice = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_h}}, info => $info, prompt => '', default => $default }
            );
            $ax->print_sql_info( $info );
            if ( ! defined $choice ) {
                if ( $stmt_type eq 'Create_Table' && @$aoa == 1 ) {
                    next COL_BY_COL;
                }
                elsif ( $stmt_type eq 'Insert' && @$aoa == 0 ) {
                    return;
                }
                else {
                    $default = 0;
                    $#$aoa--;
                    next WHAT_NEXT;
                }
            }
            elsif ( $choice eq $sf->{i}{ok} ) {
                if ( ! @$aoa ) {
                    if ( $stmt_type eq 'Create_Table' ) {
                        next COL_BY_COL;
                    }
                    elsif ( $stmt_type eq 'Insert' ) {
                        return;
                    }
                }
                else {
                    $sql->{insert_args} = $aoa;
                    return 1;
                }
            }
            elsif ( $choice eq $add ) {
                my $info = $sf->__get_read_info( $aoa );
                my $fields = [ map { [ $_, ] } @$col_names ];
                # Fill_form
                my $data = $tf->fill_form(
                    $fields,
                    { info => $info, confirm => $confirm, back => $back . '   ', prompt => 'Enter Data:' }
                );
                $ax->print_sql_info( $info );
                if ( ! defined $data ) {
                    if ( ! @$aoa ) {
                        next COL_BY_COL;
                    }
                    $default = 0;
                }
                else {
                    if ( $sf->{o}{insert}{empty_to_null_plain} ) {
                        push @{$aoa}, [ map { length( $_->[1] ) ? $_->[1] : undef } @$data ];
                    }
                    else {
                        push @{$aoa}, [ map { $_->[1] } @$data ];
                    }
                    $default = 2;
                }
            }
        }
    }
}


sub __files_in_dir {
    my ( $sf, $dir ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    if ( ! defined $dir ) {
        return [];
    }
    if ( ! -d $dir ) {
        my $message = "Directory '$dir' does not exist.\nThe entry will be removed from history.";
        $ax->print_error_message( $message );
        $sf->__remove_from_history( $dir );
        return [];
    }
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


sub __avail_directories {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $h_ref = $ax->read_json( $sf->{i}{f_dir_history} ) // {};
    my @dirs = @{$h_ref->{dirs}//[]};
    if ( @dirs > $sf->{o}{insert}{history_dirs} ) {
        $#dirs = $sf->{o}{insert}{history_dirs} - 1;
        $h_ref->{dirs} = \@dirs;
        $ax->write_json( $sf->{i}{f_dir_history}, $h_ref );
    }
    return [ sort @dirs ]; ##
}


sub __add_to_history {
    my ( $sf, $dir ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $h_ref = $ax->read_json( $sf->{i}{f_dir_history} ) // {};
    my @dirs = @{$h_ref->{dirs}//[]};
    unshift @dirs, $dir;
    @dirs = uniq @dirs;
    if ( @dirs > $sf->{o}{insert}{history_dirs} ) {
        $#dirs = $sf->{o}{insert}{history_dirs} - 1;
    }
    $h_ref->{dirs} = \@dirs;
    $ax->write_json( $sf->{i}{f_dir_history}, $h_ref );
}


sub __remove_from_history {
    my ( $sf, $dir ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $h_ref = $ax->read_json( $sf->{i}{f_dir_history} ) // {};
    my @dirs = @{$h_ref->{dirs}//[]};
    my $idx = firstidx { $_ eq $dir } @dirs;
    splice( @dirs, $idx, 1 );
    $h_ref->{dirs} = \@dirs;
    $ax->write_json( $sf->{i}{f_dir_history}, $h_ref );
}


sub __new_search_dir {
    my ( $sf ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $default_dir = $sf->{d}{default_search_dir} // $sf->{i}{home_dir};
    # Choose
    my $dir = $tu->choose_a_directory(
        { init_dir => $default_dir, decoded => 1, clear_screen => 1, confirm => '-OK-', back => '<<' }
    );
    if ( $dir ) {
        $sf->{d}{default_search_dir} = $dir;
    }
    return $dir;
}




1;


__END__
