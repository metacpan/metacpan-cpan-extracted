package # hide from PAUSE
App::DBBrowser::Opt::Set;

use warnings;
use strict;
use 5.016;

use Encode                qw( decode );
use File::Basename        qw( fileparse );
use File::Spec::Functions qw( catfile );
use FindBin               qw( $RealBin $RealScript );
#use Pod::Usage            qw( pod2usage ); # required

use Encode::Locale qw();

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
            " = ", " != ", " <> ", " < ", " > ", " >= ", " <= ",
            "REGEXP", "REGEXP_i", "NOT REGEXP", "NOT REGEXP_i", "LIKE", "NOT LIKE",
            "IS NULL", "IS NOT NULL", "IN", "NOT IN", "BETWEEN", "NOT BETWEEN",
            "ANY", "ALL",
        ],
    }, $class;
}

sub _groups {
    my $groups = [
        { name => 'group_plugins',      text => "  Plugins"   },
        { name => 'group_database',     text => "- DB Settings"  },
        { name => 'group_extensions',   text => "- Extensions"   },
        { name => 'group_sql_settings', text => "- SQL Settings" },
        { name => 'group_create',       text => "- Create Table" },
        { name => 'group_output',       text => "- Output"       },
        { name => 'group_import',       text => "- Import"       },
        { name => 'group_export',       text => "- Export"       },
        { name => 'group_misc',         text => "- Misc"         },
        { name => 'group_help',         text => "  Help"         },
        { name => 'group_path',         text => "  Path"         },
    ];
    return $groups;
}


sub _options {
    my ( $group_name ) = @_;
    my $groups = {
        group_help => [
            { name => 'help', text => '', section => '' }
        ],
        group_path => [
            { name => 'path', text => '', section => '' }
        ],
        group_plugins => [
            { name => 'plugins', text => '',  section => 'G' },
        ],
        group_database => [
            { name => '_db_defaults', text => '', section => ''  },
        ],
        group_extensions => [
            { name => '_e_table',        text => "- Tables menu",        section => 'enable' },
            { name => '_e_join',         text => "- Join menu",          section => 'enable' },
            { name => '_e_union',        text => "- Union menu",         section => 'enable' },
            { name => '_e_expressions',  text => "- Columns and Values", section => 'enable' },
            { name => '_e_write_access', text => "- Write access",       section => 'enable' },
        ],
        group_sql_settings => [
            { name => '_meta',               text => "- System data",          section => 'G'      },
            { name => 'operators',           text => "- Operators",            section => 'G'      },
            { name => '_add_aliases',        text => "- Add aliases",          section => 'alias'  },
            { name => '_aliases_in_clauses', text => "- Alias use in clauses", section => 'alias'  },
            { name => '_sql_identifiers',    text => "- Identifiers",          section => 'G'      },
            { name => '_view_name_prefix',   text => "- View prefix",          section => 'create' }, ##
            { name => '_other_sql_settings', text => "- Other",                section => 'G'      },
        ],
        group_create => [
            { name => '_enable_ct_opt',          text => "- Enable options",                     section => 'create' },
            { name => '_add_ct_fields',          text => "- Add form fields",                    section => 'create' },
            { name => '_default_ai_column_name', text => "- Default auto increment column name", section => 'create' },
        ],
        group_output => [
            { name => '_binary_filter',    text => "- Binary filter",       section => 'table' },
            { name => '_squash_spaces',    text => "- Squash spaces",       section => 'table' },
            { name => '_base_indent',      text => "- Indentation",         section => 'G'     },
            { name => '_set_string',       text => "- Undef string",        section => 'table' },
            { name => '_warningss',        text => "- Warnings",            section => 'G'     },
            { name => 'progress_bar',      text => "- Progress bar",        section => 'table' },
            { name => 'tab_width',         text => "- Tab width",           section => 'table' },
            { name => '_pad_row_edges',    text => "- Pad row edges",       section => 'table' },
            { name => 'max_width_exp',     text => "- Max width expanded",  section => 'table' },
            { name => '_color',            text => "- Color",               section => 'table' },
            { name => 'trunc_fract_first', text => "- Trunc fract first",   section => 'table' },
            { name => 'min_col_width',     text => "- Trunc col threshold", section => 'table' },
        ],
        group_import => [
            { name => '_parse_file',        text => "- Parse tool",        section => 'insert' },
            { name => '_csv_in_char',       text => "- CSV options in a",  section => 'csv_in' },
            { name => '_csv_in_options',    text => "- CSV options in b",  section => 'csv_in' },
            { name => '_split_config',      text => "- Settings 'split'",  section => 'split'  },
            { name => '_input_filter',      text => "- Input filter",      section => 'insert' },
            { name => '_empty_to_null',     text => "- Empty to Null",     section => 'insert' },
            { name => '_file_encoding_in',  text => "- File encoding in",  section => 'insert' },
            { name => 'history_dirs',       text => "- Directory history", section => 'insert' },
            { name => '_file_filter',       text => "- File filter",       section => 'insert' },
            { name => '_show_hidden_files', text => "- Hidden files",      section => 'insert' },
            { name => '_data_source_type',  text => "- Source type",       section => 'insert' },
        ],
        group_export => [
            { name => 'export_dir',         text => "- Destination folder", section => 'export'  },
            { name => '_exported_files',    text => "- File name",          section => 'export'  },
            { name => '_csv_out_char',      text => "- CSV options out a",  section => 'csv_out' },
            { name => '_csv_out_options',   text => "- CSV options out b",  section => 'csv_out' },
            { name => '_file_encoding_out', text => "- File encoding out",  section => 'export'  },
        ],
        group_misc => [
            { name => '_menu_memory',  text => "- Menu memory",  section => 'G'     },
            { name => '_table_expand', text => "- Expand table", section => 'table' },
            { name => '_search',       text => "- Search",       section => 'table' },
            { name => '_mouse',        text => "- Mouse mode",   section => 'table' },
            { name => '_db2_encoding', text => "- DB2 encoding", section => 'G'     },
        ],
    };
    return $groups->{$group_name};
}


sub set_options {
    my ( $sf, $arg_group ) = @_;
    if ( ! $sf->{o} || ! %{$sf->{o}} ) {
        my $opt_get = App::DBBrowser::Opt::Set->new( $sf->{i}, $sf->{o} );
        $sf->{o} = $opt_get->read_config_files();
    }
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $groups;
    if ( $arg_group ) {
        if ( $arg_group eq 'create' ) {
            $groups = [ { name => 'group_create', text => '' } ];
        }
        elsif ( $arg_group eq 'import' ) {
            $groups = [ { name => 'group_import', text => '' } ];
        }
        elsif ( $arg_group eq 'export' ) {
            $groups = [ { name => 'group_export', text => '' } ];
        }
        else {
            die "'$arg_group' invalid argument";
        }
    }
    else {
        $groups = _groups();
    }
    my $grp_old_idx = 0;

    GROUP: while( 1 ) {
        my ( $group_name, $group_text );
        if ( @$groups == 1 ) {
            $group_name = $groups->[0]{name};
            $group_text = $groups->[0]{text};
        }
        else {
            my @pre  = ( undef, $sf->{i}{_continue} );
            my $menu = [ @pre, map( $_->{text}, @$groups ) ];
            # Choose
            my $grp_idx = $tc->choose(
                $menu,
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
            if ( $menu->[$grp_idx] eq $sf->{i}{_continue} ) {
                if ( $sf->{write_config} ) {
                    $sf->__write_config_files();
                    delete $sf->{write_config};
                }
                return $sf->{o};
            }
            $group_name = $groups->[$grp_idx-@pre]{name};
            $group_text = $groups->[$grp_idx-@pre]{text};
        };
        my $group_prompt;
        if ( length $group_text ) {
            $group_prompt = $group_text =~ s/^- //r . ':';
        }
        my $options = _options( $group_name );
        my $opt_old_idx = 0;

        OPTION: while ( 1 ) {
            my ( $section, $opt );
            if ( @$options == 1 ) {
                $section = $options->[0]{section};
                $opt = $options->[0]{name};
            }
            else {
                my @pre  = ( undef );
                my $menu = [ @pre, map( $_->{text}, @$options ) ];
                # Choose
                my $opt_idx = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, prompt => $group_prompt,
                      index => 1, default => $opt_old_idx, undef => '  <=' }
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
                $opt = $options->[$opt_idx-@pre]{name};
            }
            my ( $no, $yes ) = ( 'NO', 'YES' );
            if ( $opt eq 'help' ) {
                require Pod::Usage;  # ctrl-c
                Pod::Usage::pod2usage( { -exitval => 'NOEXIT', -verbose => 2 } );
            }
            elsif ( $opt eq 'path' ) {
                my $app_dir = $sf->{i}{app_dir};
                eval { $app_dir = decode( 'locale', $app_dir ) };
                my $info = 'db-browser'  . "\n\n";
                $info .= 'version: ' . $main::VERSION . "\n\n";
                $info .= 'path: ' . catfile( $RealBin, $RealScript ) . "\n\n";
                $info .= 'app-dir: ' . $app_dir . "\n";
                $tc->choose( [ '<<' ], { prompt => $info, color => 1 } );
            }
            elsif ( $opt eq 'plugins' ) {
                my %installed_driver;
                for my $dir ( @INC ) {
                    my $glob_pattern = catfile $dir, 'App', 'DBBrowser', 'DB', '*.pm';
                    map { $installed_driver{( fileparse $_, '.pm' )[0]}++ } glob $glob_pattern;
                }
                my $prompt = "\n" . 'Database plugins:';
                $sf->__choose_a_subset_wrap( $section, $opt, [ sort keys %installed_driver ], $prompt );
            }
            elsif ( $opt eq '_db_defaults' ) {
                my $odb = App::DBBrowser::Opt::DBSet->new( $sf->{i}, $sf->{o} );
                $odb->database_setting();
            }
            ##### Extensions #####
            elsif ( $opt eq '_e_table' ) {
                my $prompt = 'Extend Tables Menu:';
                my $sub_menu = [
                    [ 'm_derived',   "- Add Subquery",      [ $no, $yes ] ],
                    [ 'm_cte',       "- Add Cte",         [ $no, $yes ] ],
                    [ 'join',        "- Add Join",        [ $no, $yes ] ],
                    [ 'union',       "- Add Union",       [ $no, $yes ] ],
                    [ 'db_settings', "- Add DB settings", [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_e_join' ) {
                my $prompt = 'Extend Join Menu:';
                my $sub_menu = [
                    [ 'j_derived', "- Add Subquery", [ $no, $yes ] ],
                    [ 'j_cte',     "- Add Cte",      [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_e_union' ) {
                my $prompt = 'Extend Union Menu:';
                my $sub_menu = [
                    [ 'u_derived',     "- Add Subquery",   [ $no, $yes ] ],
                    [ 'u_cte',         "- Add Cte",        [ $no, $yes ] ],
                    [ 'u_edit_stmt',   "- Edit Statement", [ $no, $yes ] ],
                    [ 'u_parentheses', "- Parentheses",    [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_e_expressions' ) {
                my $prompt = 'Extended expressions:';
                my $sub_menu = [
                    [ 'extended_cols',   "- Exdented Columns",    [ $no, $yes ] ],
                    [ 'extended_values', "- Exdented Values",     [ $no, $yes ] ],
                    [ 'extended_args',   "- Exdented Arguments",  [ $no, $yes ] ],
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
            ##### SQL Settings #####
            elsif ( $opt eq '_meta' ) {
                my $prompt = 'System data ';
                my $sub_menu = [
                    [ 'metadata', "- Show system DB/Schemas/Tables", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq 'operators' ) {
                my $prompt = 'Choose operators';
                $sf->__choose_a_subset_wrap( $section, $opt, $sf->{avail_operators}, $prompt );
            }
            elsif ( $opt eq '_add_aliases' ) {
                my $prompt = 'Add alias:';
                my $sub_menu = [
                    [ 'complex_cols_select', "- Functions/Subqueries in select",  [ 'NO',   undef, 'ASK',   undef     ] ],
                    [ 'tables_in_join',      "- Tables in join",                  [ undef, 'AUTO',  undef, 'ASK/AUTO' ] ],
                    [ 'join_columns',        "- Non-unique columns in join",      [ 'NO',  'AUTO', 'ASK',  'ASK/AUTO' ] ],
                    [ 'derived_table',       "- Derived table",                   [ 'NO',  'AUTO', 'ASK',  'ASK/AUTO' ] ],
                    [ 'ordinary_table',      "- Ordinary table",                  [ 'NO',  'AUTO', 'ASK',  'ASK/AUTO' ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_aliases_in_clauses' ) {
                my $prompt = 'Use aliases in: ';
                my $sub_menu = [
                    [ 'use_in_group_by', "- Group by", [ $no, $yes ] ],
                    [ 'use_in_having',   "- Having",   [ $no, $yes ] ],
                    [ 'use_in_order_by', "- Order by", [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_sql_identifiers' ) {
                my $prompt = 'Your choice: ';
                my $sub_menu = [
                    [ 'qualified_table_name', "- Qualified table names", [ $no, $yes ] ],
                    [ 'quote_tables',         "- Quote table names",     [ $no, $yes ] ],
                    [ 'quote_columns',        "- Quote column names",    [ $no, $yes ] ],
                    [ 'quote_aliases',        "- Quote aliases",         [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_view_name_prefix' ) {
                my $items = [
                    { name => 'view_name_prefix', prompt => "View name prefix" },
                ];
                my $prompt = 'Set a view name prefix';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq '_other_sql_settings' ) {
                my $prompt = 'Your choice: ';
                my $sub_menu = [
                    #[ 'limit_fetch_col_names', "- Fetch column names with LIMIT 0", [ $no, $yes ] ], ##
                    [ 'edit_sql_menu_sq',      "- Subqueries created with 'SQL Menu': Allow editing.", [ $no, $yes ] ],
                    [ 'pg_autocast',           "- Pg: Convert to 'text' automatically when required.", [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            ##### Create table ####
            elsif ( $opt eq '_enable_ct_opt' ) {
                my $prompt = 'Activate options';
                my $sub_menu = [
                    [ 'option_ai_column_enabled', "- Option 'Auto Increment'", [ $no, $yes ] ],
                    [ 'data_type_guessing',       "- Data type guessing",      [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_add_ct_fields' ) {
                my $prompt = 'Add fields';
                my $sub_menu = [
                    [ 'table_constraint_rows',    "- Table constraint fields", [ 0 .. 9    ] ],
                    [ 'table_option_rows',        "- Table option fields",     [ 0 .. 9    ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_default_ai_column_name' ) {
                my $items = [
                    { name => 'default_ai_column_name', prompt => "Default primary key auto increment column name" },
                ];
                my $prompt = 'Set a default auto increment column name';
                $sf->__group_readline( $section, $items, $prompt );
            }
            ##### Output ####
            elsif ( $opt eq 'min_col_width' ) {
                my $digits = 3;
                my $prompt = 'Set the minimum column width ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits, 0 );
            }
            elsif ( $opt eq 'trunc_fract_first' ) {
                my $prompt = 'If the terminal not wide enough:';
                my $sub_menu = [
                    [ 'trunc_fract_first', "- First step: truncate fraction of numbers", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq 'progress_bar' ) {
                my $digits = 7;
                my $prompt = 'Set the threshold for the progress bar ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits, 0 );
            }
            elsif ( $opt eq 'tab_width' ) {
                my $digits = 3;
                my $prompt = 'Set the tab width ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits, 0 );
            }
            elsif ( $opt eq 'max_width_exp' ) {
                my $digits = 3;
                my $prompt = 'Maximum width expanded table row';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits, 0 );
            }
            elsif ( $opt eq '_pad_row_edges' ) {
                my $prompt = '"Pad row edges"';
                my $sub_menu = [
                    [ 'pad_row_edges', "- Pad row edges with a space.", [ $no, $yes ] ]
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
                my $prompt = 'How to print arbitrary binray data';
                my $sub_menu = [
                    [ 'binary_filter', "- Binary filter", [ $no, 'BNRY', 'Hexadecimal' ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_squash_spaces' ) {
                my $prompt = 'Remove leading and trailing spaces and squash consecutive spaces';
                my $sub_menu = [
                    [ 'squash_spaces', "- Squash spaces", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_base_indent' ) {
                my $prompt = 'Set the indentation width for SQL substatements';
                my $sub_menu = [
                    [ 'base_indent', "- Indentation", [ 0, 1, 2, 3, 4 ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_set_string' ) {
                my $items = [
                    { name => 'undef', prompt => "Show undefined fields as" },
                ];
                my $prompt = 'Undef string';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq '_warningss' ) {
                my $prompt = '"Disable/Enable warnings"';
                my $sub_menu = [
                    [ 'file_find_warnings',   "- Warnings \"File::Find\" (SQLite)", [ $no, $yes ] ],
                    [ 'warnings_table_print', "- Warnings table-print",             [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            ##### Import #####
            elsif ( $opt eq '_data_source_type' ) {
                my $prompt = 'Data source options';
                my $sub_menu = [
                    [ 'data_source_create_table', "- Data source \"Create table\"", [ 'plain', 'file', 'menu' ], ],
                    [ 'data_source_insert',       "- Data source \"Insert into\"",  [ 'plain', 'file', 'menu' ], ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_parse_file' ) {
                my $prompt = 'How to parse input files';
                my $sub_menu = [
                    [ 'parse_mode_input_file', "- Use", [ 'Text::CSV', 'split', 'Template', 'Spreadsheet::Read' ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_csv_in_char' ) {
                my $items = [
                    { name => 'sep_char',    prompt => "sep_char   " },
                    { name => 'quote_char',  prompt => "quote_char " },
                    { name => 'escape_char', prompt => "escape_char" },
                    { name => 'eol',         prompt => "eol        " },
                    { name => 'comment_str', prompt => "comment_str" },
                ];
                my $prompt = 'Text::CSV_XS read options a';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq '_csv_in_options' ) {
                my $prompt = 'Text::CSV_XS read options b';
                my $sub_menu = [
                    [ 'allow_loose_escapes', "- allow_loose_escapes", [ $no, $yes ] ],
                    [ 'allow_loose_quotes',  "- allow_loose_quotes",  [ $no, $yes ] ],
                    [ 'allow_whitespace',    "- allow_whitespace",    [ $no, $yes ] ],
                    [ 'blank_is_undef',      "- blank_is_undef",      [ $no, $yes ] ],
                    [ 'binary',              "- binary",              [ $no, $yes ] ],
                    [ 'decode_utf8',         "- decode_utf8",         [ $no, $yes ] ],
                    [ 'empty_is_undef',      "- empty_is_undef",      [ $no, $yes ] ],
                    [ 'skip_empty_rows',     "- skip_empty_rows",     [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
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
            elsif ( $opt eq '_input_filter' ) {
                my $prompt = 'Enable input filter';
                my $sub_menu = [
                    [ 'enable_input_filter', "- Enable input filter", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_empty_to_null' ) {
                my $prompt = 'Enable "Empty to NULL":';
                my $sub_menu = [
                    [ 'empty_to_null_plain',  "- Source type 'plain'",  [ $no, $yes ] ],
                    [ 'empty_to_null_file',   "- Source type 'file'",   [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_file_encoding_in' ) {
                my $items = [
                    { name => 'file_encoding', prompt => "Input file encoding" },
                ];
                my $prompt = 'Encoding of input data text files';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq 'history_dirs' ) {
                my $digits = 2;
                my $prompt = 'Number of saved dirs: ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits, 1 );
            }
            elsif ( $opt eq '_file_filter' ) {
                my $items = [
                    { name => 'file_filter', prompt => "File filter glob pattern" },
                ];
                my $prompt = 'Set the glob pattern for the file filter';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq '_show_hidden_files' ) {
                my $prompt = 'Show hidden files';
                my $sub_menu = [
                    [ 'show_hidden_files', "- Show hidden files", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            ##### Export #####
            elsif ( $opt eq 'export_dir' ) {
                my $prompt = 'Choose destination folder for data exported in CSV-files';
                $sf->__choose_a_directory_wrap( $section, $opt, $prompt );
            }
            elsif ( $opt eq '_exported_files' ) {
                my $prompt = 'Exported files';
                my $sub_menu = [
                    [ 'add_extension',      "- Add automatically '.csv'-extension", [ $no, $yes ] ],
                    [ 'default_filename',   "- Table-name is default file-name", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_file_encoding_out' ) {
                my $items = [
                    { name => 'file_encoding', prompt => "Encoding CSV file" },
                ];
                my $prompt = 'Data to CSV-files';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq '_csv_out_char' ) {
                my $items = [
                    { name => 'sep_char',    prompt => "sep_char   " },
                    { name => 'quote_char',  prompt => "quote_char " },
                    { name => 'escape_char', prompt => "escape_char" },
                    { name => 'eol',         prompt => "eol        " },
                    { name => 'undef_str',   prompt => "undef_str"   },
                ];
                my $prompt = 'Text::CSV_XS write options a';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq '_csv_out_options' ) {
                my $prompt = 'Text::CSV_XS write options b';
                my $sub_menu = [
                    [ 'always_quote', "- always_quote", [ $no, $yes ] ],
                    [ 'binary',       "- binary",       [ $no, $yes ] ],
                    [ 'escape_null',  "- escape_null",  [ $no, $yes ] ],
                    [ 'quote_binary', "- quote_binary", [ $no, $yes ] ],
                    [ 'quote_empty',  "- quote_empty",  [ $no, $yes ] ],
                    [ 'quote_space',  "- quote_space",  [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            ##### misc #####
            elsif ( $opt eq '_menu_memory' ) {
                my $prompt = 'Your choice: ';
                my $sub_menu = [
                    [ 'menu_memory', "- Menu memory", [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_table_expand' ) {
                my $prompt = 'Your choice: ';
                my $sub_menu = [
                    [ 'table_expand', "- Expand table rows",   [ $no, $yes ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_search' ) {
                my $prompt = 'Your choice: ';
                my $sub_menu = [
                    [ 'search', "- Row filter", [ 'disabled', 'case insensitive', 'case sensitive' ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_mouse' ) {
                my $prompt = 'Your choice: ';
                my $sub_menu = [
                    [ 'mouse', "- Mouse mode", [ $no, $yes ] ]
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_db2_encoding' ) {
                my $items = [
                    { name => 'db2_encoding', prompt => "DB2 application code set" },
                ];
                my $prompt = 'Set the DB2 application code set';
                $sf->__group_readline( $section, $items, $prompt );
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
    # sets the options to the index of the chosen values, not to the values itself
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
          index => 0, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back}, layout => 2,
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
    my $w = $digits + int( ( $digits - 1 ) / 3 ) * length $sf->{i}{info_thsd_sep};
    my $info = 'Cur: ' . sprintf( "%*s", $w, insert_sep( $current, $sf->{i}{info_thsd_sep} ) );
    my $name = 'New: ';
    #$info = $prompt . "\n" . $info;
    # Choose_a_number
    my $choice = $tu->choose_a_number( $digits,
        { prompt => $prompt, cs_label => $name, info => $info, small_first => $small_first,
          clear_screen => 1, confirm => $sf->{i}{confirm}, back => $sf->{i}{back} }
    );
    return if ! defined $choice;
    $sf->{o}{$section}{$opt} = $choice;
    $sf->{write_config}++;
    return;
}


sub __choose_a_directory_wrap {
    my ( $sf, $section, $opt, $prompt ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    #my $current = $sf->{o}{$section}{$opt};
    my $choice = $tu->choose_a_directory(
        { show_hidden => 1, prompt => $prompt, clear_screen => 1, decoded => 1,
          confirm => $sf->{i}{confirm}, back => $sf->{i}{back} } ##
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
        { prompt => $prompt, confirm => $sf->{i}{confirm}, back => $sf->{i}{back} }
    );
    if ( $new_list ) {
        for my $i ( 0 .. $#$items ) {
            $sf->{o}{$section}{$items->[$i]{name}} = $new_list->[$i][1];
        }
        $sf->{write_config}++;
    }
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
