package # hide from PAUSE
App::DBBrowser::Opt::Set;

use warnings;
use strict;
use 5.010001;

use Encode                qw( decode );
use File::Basename        qw( fileparse );
use File::Spec::Functions qw( catfile );
use FindBin               qw( $RealBin $RealScript );
#use Pod::Usage            qw( pod2usage ); # required

use Encode::Locale  qw();

use Term::Choose       qw();
use Term::Choose::Util qw( insert_sep );
use Term::Form         qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Opt::DBSet;
use App::DBBrowser::Opt::Get;

sub new {
    my ( $class, $info, $options ) = @_;
    bless {
        i => $info,
        o => $options,
        avail_operators => [
            "REGEXP", "REGEXP_i", "NOT REGEXP", "NOT REGEXP_i", "LIKE", "NOT LIKE", "IS NULL", "IS NOT NULL",
            "IN", "NOT IN", "BETWEEN", "NOT BETWEEN", " = ", " != ", " <> ", " < ", " > ", " >= ", " <= ",
            " = col", " != col", " <> col", " < col", " > col", " >= col", " <= col",
            "LIKE %col%", "NOT LIKE %col%",  "LIKE col%", "NOT LIKE col%", "LIKE %col", "NOT LIKE %col" ],
            # "LIKE col", "NOT LIKE col"
        }, $class;
}


sub _groups {
    my $groups = [
        { name => 'group_help',     text => "  HELP"        },
        { name => 'group_path',     text => "  Path"        },
        { name => 'group_database', text => "- DB Options" },
        { name => 'group_behavior', text => "- Behavior"    },
        { name => 'group_enable',   text => "- Extensions"  },
        { name => 'group_sql',      text => "- SQL",        },
        { name => 'group_output',   text => "- Output"      },
        { name => 'group_insert',   text => "- Insert Data" },
    ];
    return $groups;
}


sub _options {
    my ( $group ) = @_;
    my $groups = {
        group_help => [
            { name => 'help', text => '', section => '' }
        ],
        group_path => [
            { name => 'path', text => '', section => '' }
        ],
        group_database => [
            { name => 'plugins',      text => "- DB Plugins",  section => 'G' },
            { name => '_db_defaults', text => "- DB Settings", section => ''  },
        ],
        group_behavior => [
            { name => '_menu_memory',  text => "- Menu memory",  section => 'G'     },
            { name => '_keep_header',  text => "- Keep header",  section => 'table' },
            { name => '_table_expand', text => "- Table expand", section => 'table' },
            { name => '_info_expand',  text => "- Info expand",  section => 'G'     },
            { name => '_mouse',        text => "- Mouse mode",   section => 'table' },
        ],
        group_enable => [
            { name => '_e_table',         text => "- Tables menu",   section => 'enable' },
            { name => '_e_join',          text => "- Join menu",     section => 'enable' },
            { name => '_e_union',         text => "- Union menu",    section => 'enable' },
            { name => '_e_substatements', text => "- Substatements", section => 'enable' },
            { name => '_e_parentheses',   text => "- Parentheses",   section => 'enable' },
            { name => '_e_write_access',  text => "- Write access",  section => 'enable' },
        ],
        group_sql => [
            { name => '_meta',                   text => "- Metadata",       section => 'G'      },
            { name => 'operators',               text => "- Operators",      section => 'G'      },
            { name => '_alias',                  text => "- Alias",          section => 'alias'  },
            { name => '_sql_identifiers',        text => "- Identifiers",    section => 'G'      },
            { name => '_autoincrement_col_name', text => "- Auto increment", section => 'create' },
            { name => '_data_type_guessing',     text => "- Data types",     section => 'create' },
            { name => 'max_rows',                text => "- Max Rows",       section => 'G'      },
        ],
        group_output => [
            { name => 'min_col_width',       text => "- Colwidth",       section => 'table' },
            { name => 'progress_bar',        text => "- ProgressBar",    section => 'table' },
            { name => 'tab_width',           text => "- Tabwidth",       section => 'table' },
            { name => '_grid',               text => "- Grid",           section => 'table' },
            { name => '_color',              text => "- Color",          section => 'table' },
            { name => '_binary_filter',      text => "- Binary filter",  section => 'table' },
            { name => '_squash_spaces',      text => "- Squash spaces",  section => 'table' },
            { name => '_set_string',         text => "- Set string",     section => 'table' },
            { name => '_file_find_warnings', text => "- Warnings",       section => 'G'     },
        ],
        group_insert => [
            { name => '_parse_file',        text => "- Parse file",     section => 'insert' },
            { name => '_parse_copy',        text => "- Parse C & P",    section => 'insert' },
            { name => '_split_config',      text => "- split settings", section => 'split'  },
            { name => '_csv_char',          text => "- CSV settings-a", section => 'csv'    },
            { name => '_csv_options',       text => "- CSV settings-b", section => 'csv'    },
            { name => '_empty_to_null',     text => "- Empty to NULL",  section => 'insert' },
            { name => '_file_encoding',     text => "- File encoding",  section => 'insert' },
            { name => 'history_dirs',       text => "- Dir history",    section => 'insert' },
            { name => '_file_filter',       text => "- File filter",    section => 'insert' },
            { name => '_show_hidden_files', text => "- Show hidden",    section => 'insert' },
        ],
    };
    return $groups->{$group};
}


sub set_options {
    my ( $sf, $arg_groups, $arg_options ) = @_;
    if ( ! $sf->{o} || ! %{$sf->{o}} ) {
        my $opt_get = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
        $sf->{o} = $opt_get->read_config_files();
    }
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $groups;
    if ( $arg_groups ) {
        $groups = [ @$arg_groups ];
    }
    else {
        $groups = _groups();
    }
    my $grp_old_idx = 0;

    GROUP: while( 1 ) {
        my $group;
        if ( @$groups == 1 ) {
            $group = $groups->[0]{name};
        }
        else {
            my @pre  = ( undef, $sf->{i}{_continue} );
            my $choices = [ @pre, map( $_->{text}, @$groups ) ];
            # Choose
            my $grp_idx = $tc->choose(
                $choices,
                { %{$sf->{i}{lyt_v}}, index => 1, default => $grp_old_idx, undef => $sf->{i}{_quit} }
            );
            if ( ! $grp_idx ) {
                if ( $sf->{write_config} ) {
                    $sf->__write_config_files();
                    delete $sf->{write_config};
                }
                exit();
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $grp_old_idx == $grp_idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $grp_old_idx = 0;
                    next GROUP;
                }
                $grp_old_idx = $grp_idx;
            }
            else {
                if ( $grp_old_idx != 0 ) {
                    $grp_old_idx = 0;
                    next GROUP;
                }
            }
            if ( $choices->[$grp_idx] eq $sf->{i}{_continue} ) {
                if ( $sf->{write_config} ) {
                    $sf->__write_config_files();
                    delete $sf->{write_config};
                }
                return $sf->{o};
            }
            $group = $groups->[$grp_idx-@pre]{name};
        };
        my $options;
        if ( $arg_options ) {
            $options = [ @$arg_options ];
        }
        else {
            $options = _options( $group );
        }
        my $opt_old_idx = 0;

        OPTION: while ( 1 ) {
            my ( $section, $opt );
            if ( @$options == 1 ) {
                $section = $options->[0]{section};
                $opt     = $options->[0]{name};
            }
            else {
                my @pre  = ( undef );
                my $choices = [ @pre, map( $_->{text}, @$options ) ];
                # Choose
                my $opt_idx = $tc->choose(
                    $choices,
                    { %{$sf->{i}{lyt_v}}, index => 1, default => $opt_old_idx, undef => '  <=' }
                );
                if ( ! $opt_idx ) {
                    if ( @$groups == 1 ) {
                        if ( $sf->{write_config} ) {
                            $sf->__write_config_files();
                            delete $sf->{write_config};
                        }
                        return $sf->{o};
                    }
                    next GROUP;
                }
                if ( $sf->{o}{G}{menu_memory} ) {
                    if ( $opt_old_idx == $opt_idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                        $opt_old_idx = 0;
                        next OPTION;
                    }
                    $opt_old_idx = $opt_idx;
                }
                else {
                    if ( $opt_old_idx != 0 ) {
                        $opt_old_idx = 0;
                        next OPTION;
                    }
                }
                $section = $options->[$opt_idx-@pre]{section};
                $opt     = $options->[$opt_idx-@pre]{name};
            }
            my ( $no, $yes ) = ( 'NO', 'YES' );
            if ( $opt eq 'help' ) {
                require Pod::Usage;  # ctrl-c
                Pod::Usage::pod2usage( { -exitval => 'NOEXIT', -verbose => 2 } );
            }
            elsif ( $opt eq 'path' ) {
                my $app_dir = $sf->{i}{app_dir};
                eval { $app_dir = decode( 'locale', $app_dir ) };
                my $info = 'db-browser:'                                  . "\n";
                $info .= '  version  ' . $main::VERSION                   . "\n";
                $info .= '  path     ' . catfile( $RealBin, $RealScript ) . "\n";
                $info .= '  app-dir  ' . $app_dir;
                $tc->choose( [ '<<' ], { prompt => $info, color => 1 } );
            }
            elsif ( $opt eq '_db_defaults' ) {
                my $odb = App::DBBrowser::Opt::DBSet->new( $sf->{i}, $sf->{o} );
                $odb->database_setting();
            }
            elsif ( $opt eq 'plugins' ) {
                my %installed_driver;
                for my $dir ( @INC ) {
                    my $glob_pattern = catfile $dir, 'App', 'DBBrowser', 'DB', '*.pm';
                    map { $installed_driver{( fileparse $_, '.pm' )[0]}++ } glob $glob_pattern;
                }
                my $prompt = 'Choose DB plugins';
                $sf->__choose_a_subset_wrap( $section, $opt, [ sort keys %installed_driver ], $prompt );
            }
            elsif ( $opt eq 'operators' ) {
                my $prompt = 'Choose operators';
                $sf->__choose_a_subset_wrap( $section, $opt, $sf->{avail_operators}, $prompt );
            }
            elsif ( $opt eq '_file_encoding' ) {
                my $items = [
                    { name => 'file_encoding', prompt => "file_encoding" },
                ];
                my $prompt = 'Encoding CSV files';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq '_file_filter' ) {
                my $items = [
                    { name => 'file_filter', prompt => "file_filter" },
                ];
                my $prompt = 'Set glob file filter';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq '_csv_char' ) {
                my $items = [
                    { name => 'sep_char',    prompt => "sep_char   " },
                    { name => 'quote_char',  prompt => "quote_char " },
                    { name => 'escape_char', prompt => "escape_char" },
                    { name => 'eol',         prompt => "eol        " },
                ];
                my $prompt = 'Text::CSV a';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq '_split_config' ) {
                my $items = [
                    { name => 'field_sep',     prompt => "Field separator  " },
                    { name => 'field_l_trim',  prompt => "Trim field left  " },
                    { name => 'field_r_trim',  prompt => "Trim field right " },
                    { name => 'record_sep',    prompt => "Record separator " },
                    { name => 'record_l_trim', prompt => "Trim record left " },
                    { name => 'record_r_trim', prompt => "Trim record right" },

                ];
                my $prompt = 'Config \'split\' mode';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq '_set_string' ) {
                my $items = [
                    { name => 'decimal_separator', prompt => "Decimal separator" },
                    { name => 'undef',             prompt => "Undefined field  " },
                ];
                my $prompt = 'Set strings';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq '_autoincrement_col_name' ) {
                my $items = [
                    { name => 'autoincrement_col_name', prompt => "AI column name" },
                ];
                my $prompt = 'Default auto increment column name';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq 'history_dirs' ) {
                my $digits = 2;
                my $prompt = 'Number of saved dirs: ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits, 1 );
            }
            elsif ( $opt eq 'tab_width' ) {
                my $digits = 3;
                my $prompt = 'Set the tab width ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits, 0 );
            }
            elsif ( $opt eq 'min_col_width' ) {
                my $digits = 3;
                my $prompt = 'Set the minimum column width ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits, 0 );
            }
            elsif ( $opt eq 'progress_bar' ) {
                my $digits = 7;
                my $prompt = 'Set the threshold for the progress bar ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits, 0 );
            }
            elsif ( $opt eq 'max_rows' ) {
                my $digits = 7;
                my $prompt = 'Set the SQL auto LIMIT ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits, 0 );
            }
            elsif ( $opt eq '_parse_file' ) {
                my $prompt = 'Parsing "File"';
                my $sub_menu = [
                    [ 'parse_mode_input_file', "- Use:", [ 'Text::CSV', 'split', 'Template', 'Spreadsheet::Read' ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_parse_copy' ) {
                my $prompt = 'Parsing "Copy & Paste"';
                my $sub_menu = [
                    [ 'parse_mode_input_copy', "- Use:", [ 'Text::CSV', 'split', 'Template' ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_csv_options' ) {
                my $prompt = 'Text::CSV b';
                my $sub_menu = [
                    [ 'allow_loose_escapes', "- allow_loose_escapes", [ $no, $yes ] ],
                    [ 'allow_loose_quotes',  "- allow_loose_quotes",  [ $no, $yes ] ],
                    [ 'allow_whitespace',    "- allow_whitespace",    [ $no, $yes ] ],
                    [ 'blank_is_undef',      "- blank_is_undef",      [ $no, $yes ] ],
                    [ 'binary',              "- binary",              [ $no, $yes ] ],
                    [ 'empty_is_undef',      "- empty_is_undef",      [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_empty_to_null' ) {
                my $prompt = 'Enable "Empty to NULL" by default:';
                my $sub_menu = [
                    [ 'empty_to_null_plain',  "- Source type 'plain'",  [ $no, $yes ] ],
                    [ 'empty_to_null_copy',   "- Source type 'copy'",   [ $no, $yes ] ],
                    [ 'empty_to_null_file',   "- Source tpye 'file'",   [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_grid' ) {
                my $prompt = '"Grid"';
                my $sub_menu = [
                    [ 'grid', "- Grid", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }

            elsif ( $opt eq '_color' ) {
                my $prompt = '"ANSI color escapes"';
                my $sub_menu = [
                    [ 'color', "- ANSI color escapes", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_binary_filter' ) {
                my $prompt = 'Print "BNRY" instead of binary data';
                my $sub_menu = [
                    [ 'binary_filter', "- Binary filter", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_squash_spaces' ) {
                my $prompt = '"Remove leading and trailing spaces and squash consecutive spaces"';
                my $sub_menu = [
                    [ 'squash_spaces', "- Squash spaces", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_file_find_warnings' ) {
                my $prompt = '"SQLite database search"';
                my $sub_menu = [
                    [ 'file_find_warnings', "- Enable \"File::Find\" warnings", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_meta' ) {
                my $prompt = 'DB/schemas/tables ';
                my $sub_menu = [
                    [ 'metadata', "- Add metadata", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_alias' ) {
                my $prompt = 'Alias for:';
                my $sub_menu = [
                    [ 'aggregate',  "- Aggregate",  [ $no, $yes ] ], # s - p
                    [ 'functions',  "- Functions",  [ $no, $yes ] ],
                    [ 'join',       "- Join",       [ $no, $yes ] ],
                    [ 'subqueries', "- Subqueries", [ $no, $yes ] ],
                    [ 'union',      "- Union",      [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_menu_memory' ) {
                my $prompt = 'Choose: ';
                my $sub_menu = [
                    [ 'menu_memory', "- Menu memory", [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_keep_header' ) {
                my $prompt = '"Header each Page"';
                my $sub_menu = [
                    [ 'keep_header', "- Keep header", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_table_expand' ) {
                my $prompt = 'Choose: ';
                my $sub_menu = [
                    [ 'table_expand', "- Expand table rows",   [ $no, $yes . ' - fast back', $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_info_expand' ) {
                my $prompt = 'Choose: ';
                my $sub_menu = [
                    [ 'info_expand', "- Expand info-table rows",   [ $no, $yes . ' - fast back', $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_mouse' ) {
                my $prompt = 'Choose: ';
                my $sub_menu = [
                    [ 'mouse', "- Mouse mode", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_e_table' ) {
                my $prompt = 'Extend Tables Menu:';
                my $sub_menu = [
                    [ 'm_derived',   "- Add Derived",     [ $no, $yes ] ],
                    [ 'join',        "- Add Join",        [ $no, $yes ] ],
                    [ 'union',       "- Add Union",       [ $no, $yes ] ],
                    [ 'db_settings', "- Add DB settings", [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_e_join' ) {
                my $prompt = 'Extend Join Menu:';
                my $sub_menu = [
                    [ 'j_derived', "- Add Derived", [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_e_union' ) {
                my $prompt = 'Extend Union Menu:';
                my $sub_menu = [
                    [ 'u_derived', "- Add Derived",   [ $no, $yes ] ],
                    [ 'union_all', "- Add Union All", [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_e_substatements' ) {
                my $prompt = 'Substatement Additions:';
                my $sub_menu = [
                    [ 'expand_select',   "- SELECT",   [ 'None', 'Func', 'SQ',       'Func/SQ'    ] ],
                    [ 'expand_where',    "- WHERE",    [ 'None', 'Func', 'SQ',       'Func/SQ'    ] ],
                    [ 'expand_group_by', "- GROUB BY", [ 'None', 'Func', 'SQ',       'Func/SQ'    ] ],
                    [ 'expand_having',   "- HAVING",   [ 'None', 'Func', 'SQ',       'Func/SQ'    ] ],
                    [ 'expand_order_by', "- ORDER BY", [ 'None', 'Func', 'SQ',       'Func/SQ'    ] ],
                    [ 'expand_set',      "- SET",      [ 'None', 'Func', 'SQ', '=N', 'Func/SQ/=N' ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_e_parentheses' ) {
                my $prompt = 'Parentheses in WHERE/HAVING:';
                my $sub_menu = [
                    [ 'parentheses', "- Add Parentheses", [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_e_write_access' ) {
                my $prompt = 'Write access: ';
                my $sub_menu = [
                    [ 'insert_into',  "- Insert Records", [ $no, $yes ] ],
                    [ 'update',       "- Update Records", [ $no, $yes ] ],
                    [ 'delete',       "- Delete Records", [ $no, $yes ] ],
                    [ 'create_table', "- Create Table",   [ $no, $yes ] ],
                    [ 'drop_table',   "- Drop   Table",   [ $no, $yes ] ],
                    [ 'create_view',  "- Create View",    [ $no, $yes ] ],
                    [ 'drop_view',    "- Drop   View",    [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_sql_identifiers' ) {
                my $prompt = 'Choose: ';
                my $sub_menu = [
                    [ 'qualified_table_name', "- Qualified table names", [ $no, $yes ] ],
                    [ 'quote_identifiers',    "- Quote identifiers",     [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_data_type_guessing' ) {
                my $prompt = 'Data type guessing';
                my $sub_menu = [
                    [ 'data_type_guessing', "- Enable data type guessing", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_show_hidden_files' ) {
                my $prompt = 'Show hidden files';
                my $sub_menu = [
                    [ 'show_hidden_files', "- Show hidden files", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq 'add_file_dir' ) {
                $sf->__new_dir_search();
            }
            else {
                die "Unknown option: $opt";
            }
            if ( @$options == 1 ) {
                if ( @$groups == 1 ) {
                    if ( $sf->{write_config} ) {
                        $sf->__write_config_files();
                        delete $sf->{write_config};
                    }
                    return $sf->{o};
                }
                else {
                    next GROUP;
                }
            }
        }
    }
}


sub __settings_menu_wrap {
    my ( $sf, $section, $sub_menu, $prompt ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $changed = $tu->settings_menu(
        $sub_menu, $sf->{o}{$section},
        { prompt => $prompt, back => $sf->{i}{_back}, confirm => $sf->{i}{_confirm} }
    );
    return if ! $changed;
    $sf->{write_config}++;
}


sub __choose_a_subset_wrap {
    my ( $sf, $section, $opt, $available, $prompt ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $current = $sf->{o}{$section}{$opt};
    # Choose_list
    my $info = 'Cur: ' . join( ', ', @$current );
    my $name = 'New: ';
    my $list = $tu->choose_a_subset(
        $available,
        { prompt => $prompt, cs_label => $name, info => $info, prefix => '- ', keep_chosen => 0,
          index => 0, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back}, layout => 3,
          clear_screen => 1 }
    );
    return if ! defined $list;
    return if ! @$list;
    $sf->{o}{$section}{$opt} = $list;
    $sf->{write_config}++;
    return;
}


sub __choose_a_number_wrap {
    my ( $sf, $section, $opt, $prompt, $digits, $small_first ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $current = $sf->{o}{$section}{$opt};
    my $w = $digits + int( ( $digits - 1 ) / 3 ) * length $sf->{o}{G}{thsd_sep};
    my $info = 'Cur: ' . sprintf( "%*s", $w, insert_sep( $current, $sf->{o}{G}{thsd_sep} ) );
    my $name = 'New: ';
    #$info = $prompt . "\n" . $info;
    # Choose_a_number
    my $choice = $tu->choose_a_number( $digits,
        { prompt => $prompt, cs_label => $name, info => $info, small_first => $small_first, clear_screen => 1 }
    );
    return if ! defined $choice;
    $sf->{o}{$section}{$opt} = $choice;
    $sf->{write_config}++;
    return;
}


sub __group_readline {
    my ( $sf, $section, $items, $prompt ) = @_;
    my $list = [ map {
        [
            exists $_->{prompt} ? $_->{prompt} : $_->{name},
            $sf->{o}{$section}{$_->{name}}
        ]
    } @{$items} ];
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $new_list = $tf->fill_form(
        $list,
        { prompt => $prompt, auto_up => 2, confirm => $sf->{i}{confirm}, back => $sf->{i}{back} }
    );
    if ( $new_list ) {
        for my $i ( 0 .. $#$items ) {
            $sf->{o}{$section}{$items->[$i]{name}} = $new_list->[$i][1];
        }
        $sf->{write_config}++;
    }
}


sub __new_dir_search { # used in Read.pm
    my ( $sf ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $default_dir = $sf->{i}{tmp_files_dir} || $sf->{i}{home_dir};
    # Choose
    my $dir_fs = $tu->choose_a_directory(
        { init_dir => $default_dir, decoded => 0, clear_screen => 1 }
    );
    if ( $dir_fs ) {
        $sf->{i}{tmp_files_dir} = $dir_fs;
    }
    $sf->{o}{insert}{add_file_dir} = $dir_fs; # don't keep saved value even if $dir_fs is not defined
}


sub __write_config_files {
    my ( $sf ) = @_;
    my $tmp = {};
    for my $section ( keys %{$sf->{o}} ) {
        for my $opt ( keys %{$sf->{o}{$section}} ) {
            $tmp->{$section}{$opt} = $sf->{o}{$section}{$opt};
        }
    }
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, {} );
    my $file_name_fs = $sf->{i}{f_settings};
    $ax->write_json( $file_name_fs, $tmp  );
}




1;


__END__
