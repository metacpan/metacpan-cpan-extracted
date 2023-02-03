package # hide from PAUSE
App::DBBrowser::GetContent;

use warnings;
use strict;
use 5.014;

use Encode         qw( encode );
use File::Basename qw( basename );

use Encode::Locale  qw();

use Term::Choose qw();

use App::DBBrowser::GetContent::Filter;
use App::DBBrowser::GetContent::Parse;
use App::DBBrowser::GetContent::Source;
#use App::DBBrowser::Opt::Set               # required

use open ':encoding(locale)';


sub new {
    my ( $class, $info, $options, $d ) = @_;
    my $sf = {
        i => $info,
        o => $options,
        d => $d
    };
    bless $sf, $class;
}


sub get_content {
    my ( $sf, $sql, $source, $goto_filter ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cs = App::DBBrowser::GetContent::Source->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cp = App::DBBrowser::GetContent::Parse->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $cf = App::DBBrowser::GetContent::Filter->new( $sf->{i}, $sf->{o}, $sf->{d} );
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my @choices = (
        [ 'plain', '- Plain' ],
        [ 'file',  '- From File' ],
    );
    my $data_source_choice_idx = $sf->{o}{insert}{'data_source_' . $sf->{d}{stmt_types}[0]};
    $source->{old_idx_menu} //= 0;

    MENU: while ( 1 ) {
        if ( $goto_filter ) {
            # keep current source type
        }
        elsif ( $data_source_choice_idx =~ /^(?:0|1)\z/ ) {
            $source->{source_type} = $choices[$data_source_choice_idx][0];
        }
        else {
            my $prompt = 'Source type:';
            my @pre = ( undef );
            my $menu = [ @pre, map( $_->[1], @choices ) ];
            # Choose
            my $idx = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1, default => $source->{old_idx_menu},
                    undef => '  <=' }
            );
            if ( ! defined $idx || ! defined $menu->[$idx] ) {
                return;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $source->{old_idx_menu} == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $source->{old_idx_menu} = 0;
                    next MENU;
                }
                $source->{old_idx_menu} = $idx;
            }
            $source->{source_type} = $choices[$idx-@pre][0];
        }
        if ( $source->{source_type} eq 'plain' ) {
            my $ok = $cs->from_col_by_col( $sql );
            if ( ! $ok ) {
                return if $data_source_choice_idx =~ /^(?:0|1)\z/;
                $goto_filter = 0;
                next MENU;
            }
            return 1;
        }
        $source->{old_idx_dir} //= 0;

        DIR: while ( 1 ) {
            if ( $goto_filter ) {
                # keep current source dir
            }
            elsif ( ! $sf->{o}{insert}{history_dirs} ) {
                $source->{dir} = $cs->__new_search_dir();
                if ( ! length $source->{dir} ) {
                    return if $data_source_choice_idx =~ /^(?:0|1)\z/;
                    next MENU;
                }
            }
            elsif ( $sf->{o}{insert}{history_dirs} == 1 ) {
                my $dirs = $cs->__avail_directories();
                if ( ! @$dirs ) {
                    $source->{dir} = $cs->__new_search_dir();
                    if ( ! length $source->{dir} ) {
                        return if $data_source_choice_idx =~ /^(?:0|1)\z/;
                        next MENU;
                    }
                }
                else{
                    $source->{dir} = $dirs->[0];
                }
            }
            else {
                my $dirs = $cs->__avail_directories();
                my $prompt = 'Choose a Dir:';
                my $new_search = '  NEW search';
                my @pre = ( undef, $new_search );
                my $menu = [ @pre, map( '- ' . $_, @$dirs ) ];
                # Choose
                my $idx = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1, default => $source->{old_idx_dir}, undef => '  <=' }
                );
                if ( ! defined $idx || ! defined $menu->[$idx] ) {
                    return if $data_source_choice_idx =~ /^(?:0|1)\z/;
                    next MENU;
                }
                if ( $sf->{o}{G}{menu_memory} ) {
                    if ( $source->{old_idx_dir} == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                        $source->{old_idx_dir} = 0;
                        next DIR;
                    }
                    $source->{old_idx_dir} = $idx;
                }
                if ( $menu->[$idx] eq $new_search ) {
                    $source->{dir} = $cs->__new_search_dir();
                    if ( ! length $source->{dir} ) {
                        next DIR;
                    }
                }
                else {
                    $source->{dir} = $dirs->[$idx-@pre];
                }
            }
            $cs->__add_to_history( $source->{dir} );
            my $files_in_chosen_dir = $cs->__files_in_dir( $source->{dir} );
            if ( $goto_filter && ! $sf->{o}{insert}{enable_input_filter} && ! $source->{saved_book} ) {
                $goto_filter = 0;
            }
            $source->{old_idx_file} //= 0;

            FILE: while ( 1 ) {
                if ( $goto_filter ) {
                    # keep current source file
                }
                else {
                    my $prompt = 'Choose a File:';
                    my @pre = ( undef );
                    my $change_dir = '  Change dir';
                    if ( $sf->{o}{insert}{history_dirs} == 1 ) {
                        push @pre, $change_dir;
                    }
                    my $menu = [ @pre, map { '  ' . basename $_ } @$files_in_chosen_dir ]; #
                    # Choose
                    my $idx = $tc->choose(
                        $menu,
                        { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1, default => $source->{old_idx_file},
                        undef => '  <=' }
                    );
                    if ( ! defined $idx || ! defined $menu->[$idx] ) {
                        if ( $sf->{o}{insert}{history_dirs} == 1 ) {
                            return if $data_source_choice_idx =~ /^(?:0|1)\z/;
                            next MENU;
                        }
                        next DIR;
                    }
                    if ( $sf->{o}{G}{menu_memory} ) {
                        if ( $source->{old_idx_file} == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                            $source->{old_idx_file} = 0;
                            next FILE;
                        }
                        $source->{old_idx_file} = $idx;
                    }
                    if ( $menu->[$idx] eq $change_dir ) {
                        $source->{dir} = $cs->__new_search_dir();
                        if ( length $source->{dir} ) {
                            $files_in_chosen_dir = $cs->__files_in_dir( $source->{dir} );
                        }
                        next FILE;
                    }
                    else {
                        my $old_file_fs = $source->{file_fs};
                        $source->{file_fs} = encode( 'locale_fs', $files_in_chosen_dir->[$idx-@pre] );
                        if ( ! defined $old_file_fs || $old_file_fs ne $source->{file_fs} ) {
                            delete $source->{saved_book};
                            delete $source->{sheet_name};
                        }
                    }
                }
                my $parse_mode_idx = $sf->{o}{insert}{parse_mode_input_file};
                if ( $goto_filter && ! $sf->{o}{insert}{enable_input_filter} ) {
                    $goto_filter = 0;
                }

                PARSE: while ( 1 ) {
                    if ( $goto_filter ) {
                        # keep current insert_into_args
                    }
                    else {
                        $sql->{insert_into_args} = [];
                        if ( $parse_mode_idx < 3 && -T $source->{file_fs} ) {
                            my $open_mode;
                            if ( length $sf->{o}{insert}{file_encoding} ) {
                                $open_mode = '<:encoding(' . $sf->{o}{insert}{file_encoding} . ')';
                            }
                            else {
                                $open_mode = '<';
                            }
                            open my $fh, $open_mode, $source->{file_fs} or die $!;
                            my $parse_ok;
                            if ( $parse_mode_idx == 0 ) {
                                $parse_ok = $cp->parse_with_Text_CSV( $sql, $fh );
                            }
                            elsif ( $parse_mode_idx == 1 ) {
                                $parse_ok = $cp->parse_with_split( $sql, $fh );
                            }
                            elsif ( $parse_mode_idx == 2 ) {
                                $parse_ok = $cp->parse_with_template( $sql, $fh );
                                if ( $parse_ok && $parse_ok == -1 ) { # reparse
                                    next PARSE;
                                }
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
                        }
                        else {
                            SHEET: while ( 1 ) {
                                my $ok = $cp->parse_with_Spreadsheet_Read( $sql, $source, $source->{file_fs} );
                                if ( ! $ok ) {
                                    next FILE;
                                }
                                if ( ! @{$sql->{insert_into_args}} ) { #
                                    next SHEET if $source->{saved_book};
                                    next FILE;
                                }
                                last SHEET;
                            }
                        }
                    }
                    if ( ! $sf->{o}{insert}{enable_input_filter} ) {
                        return 1;
                    }
                    $goto_filter = 0;

                    FILTER: while ( 1 ) {
                        my $ok = $cf->input_filter( $sql, $source );
                        if ( ! $ok ) {
                            if ( $source->{saved_book} ) {
                                next PARSE;
                            }
                            next FILE;
                        }
                        elsif ( $ok == -1 ) { # -1 -> REPARSE
                            require App::DBBrowser::Opt::Set;
                            my $opt_set = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
                            $opt_set->set_options( 'import' );
                            next PARSE;
                        }
                        return 1;
                    }
                }
            }
        }
    }
}






1;


__END__
