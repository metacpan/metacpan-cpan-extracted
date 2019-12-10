package # hide from PAUSE
App::DBBrowser::GetContent;

use warnings;
use strict;
use 5.010001;

use List::MoreUtils qw( none );
use Encode::Locale  qw();

use Term::Choose qw();

use App::DBBrowser::GetContent::Filter;
use App::DBBrowser::GetContent::Parse;
use App::DBBrowser::GetContent::Read;
#use App::DBBrowser::Opt::Set               # required

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



sub __setting_menu_entries {
    my ( $sf, $all ) = @_;
    my $groups = [
        { name => 'group_insert', text => '' }
    ];
    my $options = [
        { name => '_parse_file',    text => "- Parse tool for File",         section => 'insert' },
        { name => '_parse_copy',    text => "- Parse tool for Copy & Paste", section => 'insert' },
        { name => '_split_config',  text => "- Settings 'split'",            section => 'split'  },
        { name => '_csv_char',      text => "- Settings 'CSV-a'",            section => 'csv'    },
        { name => '_csv_options',   text => "- Settings 'CSV-b'",            section => 'csv'    },
    ];
    if ( ! $all ) {
        if ( defined $sf->{i}{gc}{source_type} ) {
            if ( $sf->{i}{gc}{source_type} =~ /file/i ) {
                splice @$options, 1, 1;
            }
            elsif ( $sf->{i}{gc}{source_type} =~ /paste/i ) {
                splice @$options, 0, 1;
            }
        }
    }
    return $groups, $options;
}



sub get_content {
    my ( $sf, $sql, $goto_FILTER ) = @_;
    my $cr = App::DBBrowser::GetContent::Read->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cp = App::DBBrowser::GetContent::Parse->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @cu_keys = ( qw/from_plain from_file from_copy/ );
    my %cu = ( from_plain => '- Plain',
               from_copy  => '- Copy & Paste',
               from_file  => '- From File',
    );
    my $old_idx = 1;

    MENU: while ( 1 ) {
        if ( ! $goto_FILTER ) {
            my $hidden = "Choose type of data source:";
            my $choices = [ $hidden, undef, @cu{@cu_keys} ];
            # Choose
            my $idx = $tc->choose(
                $choices,
                { %{$sf->{i}{lyt_v_clear}}, prompt => '', index => 1, default => $old_idx, undef => '  <=' }
            );
            if ( ! defined $idx || ! defined $choices->[$idx] ) {
                return;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx = 1;
                    next MENU;
                }
                $old_idx = $idx;
            }
            if ( $choices->[$idx] eq $hidden ) {
                require App::DBBrowser::Opt::Set;
                my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
                my $info = "Parse options:";
                $opt_set->set_options( $sf->__setting_menu_entries( 1 ), $info );
                next MENU;
            }
            else {
                $sf->{i}{gc}{source_type} = $choices->[$idx];
            }
            my $stmt_type = 'Insert';
            push @{$sf->{i}{stmt_types}}, $stmt_type if none { $stmt_type eq $_ } @{$sf->{i}{stmt_types}}; #
        }

        GET_DATA: while ( 1 ) {
            my ( $aoa, $open_mode );
            if ( ! $goto_FILTER ) {
                delete $sf->{i}{ct}{default_table_name};
                delete $sf->{i}{gc}{sheet_name};
                my $ok;
                if ( $sf->{i}{gc}{source_type} eq $cu{from_plain} ) {
                    ( $ok, $aoa ) = $cr->from_col_by_col( $sql );
                }
                elsif ( $sf->{i}{gc}{source_type} eq $cu{from_copy} ) {
                    ( $ok, $sf->{i}{gc}{file_ec} ) = $cr->from_copy_and_paste( $sql );
                }
                elsif ( $sf->{i}{gc}{source_type} eq $cu{from_file} ) {
                    ( $ok, $sf->{i}{gc}{file_ec} ) = $cr->from_file( $sql );
                }
                if ( ! $ok ) {
                    next MENU;
                }
                $sf->{i}{gc}{sheet_count} = 0;
                $sf->{i}{gc}{book} = undef;
            }

            PARSE: while ( 1 ) {
                if ( ! $goto_FILTER ) {
                    my ( $parse_mode_idx, $open_mode );
                    if ( $sf->{i}{gc}{source_type} eq $cu{from_copy} ) {
                        $parse_mode_idx = $sf->{o}{insert}{parse_mode_input_copy};
                        $open_mode = '<';
                    }
                    elsif ( $sf->{i}{gc}{source_type} eq $cu{from_file} ) {
                        $parse_mode_idx = $sf->{o}{insert}{parse_mode_input_file};
                        $open_mode = '<:encoding(' . $sf->{o}{insert}{file_encoding} . ')';
                    }
                    $sql->{insert_into_args} = [];
                    if ( $sf->{i}{gc}{source_type} eq $cu{from_plain} ) {
                        $sql->{insert_into_args} = $aoa;
                    }
                    elsif ( $parse_mode_idx < 3 && -T $sf->{i}{gc}{file_ec} ) {
                        open my $fh, $open_mode, $sf->{i}{gc}{file_ec} or die $!;
                        my $parse_ok;
                        if ( $parse_mode_idx == 0 ) {
                            $parse_ok = $cp->__parse_with_Text_CSV( $sql, $fh );
                        }
                        elsif ( $parse_mode_idx == 1 ) {
                            $parse_ok = $cp->__parse_with_split( $sql, $fh );
                        }
                        elsif ( $parse_mode_idx == 2 ) {
                            $parse_ok = $cp->__parse_with_template( $sql, $fh );
                            if ( $parse_ok && $parse_ok == -1 ) {
                                next PARSE;
                            }
                        }
                        if ( ! $parse_ok ) {
                            next GET_DATA;
                        }
                        if ( ! @{$sql->{insert_into_args}} ) {
                            $tc->choose(
                                [ 'empty file!' ],
                                { prompt => 'Press ENTER' }
                            );
                            close $fh;
                            next GET_DATA;
                        }
                    }
                    else {
                        SHEET: while ( 1 ) {
                            $sf->{i}{gc}{sheet_count} = $cp->__parse_with_Spreadsheet_Read( $sql, $sf->{i}{gc}{file_ec} );
                            if ( ! $sf->{i}{gc}{sheet_count} ) {
                                next GET_DATA;
                            }
                            if ( ! @{$sql->{insert_into_args}} ) { #
                                next SHEET if $sf->{i}{gc}{sheet_count} >= 2;
                                next GET_DATA;
                            }
                            last SHEET;
                        }
                    }
                    $sf->{i}{gc}{bu_insert_into_args} = [ map { [ @$_ ] } @{$sql->{insert_into_args}} ];
                }
                $goto_FILTER = 0;

                FILTER: while ( 1 ) {
                    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} ); ##
                    my $ok = $cf->input_filter( $sql, 0 );
                    if ( ! $ok ) {
                        if ( $sf->{i}{gc}{sheet_count} >= 2 ) {
                            next PARSE;
                        }
                        next GET_DATA;
                    }
                    elsif ( $ok == -1 ) {
                        #if ( ! -T $sf->{i}{gc}{file_ec} ) {
                        #    $tc->choose(
                        #        [ 'Press ENTER' ],
                        #        { prompt => 'Not a text file: "Spreadsheet::Read" is used automatically' }
                        #    );
                        #    next FILTER;
                        #}
                        require App::DBBrowser::Opt::Set;
                        my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
                        $sf->{o} = $opt_set->set_options( $sf->__setting_menu_entries() );
                        next PARSE;
                    }
                    return 1;
                }
            }
        }
    }
}









1;


__END__
