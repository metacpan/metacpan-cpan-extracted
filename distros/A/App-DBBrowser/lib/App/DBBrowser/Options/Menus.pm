package # hide from PAUSE
App::DBBrowser::Options::Menus;

use warnings;
use strict;
use 5.016;

use File::Basename        qw( fileparse );
use File::Spec::Functions qw( catfile );

use Term::Choose       qw();
use Term::Choose::Util qw( insert_sep );
use Term::Form         qw();


sub new {
    my ( $class, $info, $options ) = @_;
    bless {
        i => $info,
        o => $options,
    }, $class;
}


sub groups {
    my ( $sf, $plugin, $db ) = @_;
    my $groups;
    if ( $db ) {
        $groups = [
            { name => 'group_connect', text => "- Connect data" }, ##
        ];
    }
    elsif ( $plugin ) {
        $groups = [
            { name => 'group_connect',      text => "- Connect data" }, ##
            { name => 'group_extensions',   text => "- Extensions"   },
            { name => 'group_sql_settings', text => "- SQL settings" },
            { name => 'group_create_table', text => "- Create table" },
            { name => 'group_output',       text => "- Output"       },
            { name => 'group_import',       text => "- Import"       },
            { name => 'group_export',       text => "- Export"       },
            { name => 'group_misc',         text => "- Misc"         },
        ];
    }
    else {
        $groups = [
            { name => 'group_select_plugins', text => "- Select plugins" },
            { name => 'group_global',         text => "- Global settings" },
        ];
    }
    return $groups;
}


sub sub_groups {
    my ( $sf, $group, $driver ) = @_;
    if ( $group eq 'group_connect' ) {
        if ( $driver =~ /^(?:SQLite|DuckDB)\z/ ) {
            return [
                { name => '_read_attributes',   text => "- Read attributes",    section => 'connect_attr' },
                { name => '_set_attributes',    text => "- Set attributes",     section => 'connect_attr' },
            ];
        }
        else {
            return [
                { name => '_required_fields',   text => "- Required fields",    section => 'connect_data' },
                { name => '_login_data',        text => "- Login data",         section => 'connect_data' },
                { name => '_env_variables',     text => "- ENV variables",      section => 'connect_data' },
                { name => '_read_attributes',   text => "- Read attributes",    section => 'connect_attr' },
                { name => '_set_attributes',    text => "- Set attributes",     section => 'connect_attr' },
            ];
        }
    }
    my $groups = {
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
        group_create_table => [
            { name => '_enable_ct_opt',          text => "- Enable options",                     section => 'create' },
            { name => '_add_ct_fields',          text => "- Add form fields",                    section => 'create' },
            { name => '_default_ai_column_name', text => "- Default auto increment column name", section => 'create' }, ##
        ],
        group_output => [
            { name => '_binary_filter',    text => "- Binary filter",           section => 'table' },
            { name => '_squash_spaces',    text => "- Squash spaces",           section => 'table' },
            { name => '_set_string',       text => "- Undef string",            section => 'table' },
            { name => '_color',            text => "- Color",                   section => 'table' },
            { name => 'trunc_fract_first', text => "- Trunc fract first",       section => 'table' },
            { name => '_base_indent',      text => "- Indentation SQL",         section => 'G'     },
            { name => '_pad_row_edges',    text => "- Pad row edges",           section => 'table' },
            { name => 'tab_width',         text => "- Tab width",               section => 'table' },
            { name => '_expand_rows',      text => "- Expand table rows",       section => 'table' },
            { name => 'max_width_exp',     text => "- Max width expanded rows", section => 'table' },
            { name => 'min_col_width',     text => "- Trunc col threshold",     section => 'table' },
        ],
        group_import => [
            { name => '_parse_file',        text => "- Parse tool",        section => 'insert' },
            { name => '_csv_in_char',       text => "- CSV options a",     section => 'csv_in' },
            { name => '_csv_in_options',    text => "- CSV options b",     section => 'csv_in' },
            { name => '_split_config',      text => "- Settings 'split'",  section => 'split'  },
            { name => '_input_filter',      text => "- Input filter",      section => 'insert' },
            { name => '_empty_to_null',     text => "- Empty to null",     section => 'insert' },
            { name => '_file_encoding_in',  text => "- File encoding",     section => 'insert' },
            { name => '_file_filter',       text => "- File filter",       section => 'insert' },
            { name => '_show_hidden_files', text => "- Hidden files",      section => 'insert' },
            { name => 'history_dirs',       text => "- Directory history", section => 'insert' },
            { name => '_data_source_type',  text => "- Source type",       section => 'insert' },
        ],
        group_export => [
            { name => 'export_dir',         text => "- Destination folder", section => 'export'  },
            { name => '_exported_files',    text => "- File name",          section => 'export'  },
            { name => '_csv_out_char',      text => "- CSV options a out",  section => 'csv_out' },
            { name => '_csv_out_options',   text => "- CSV options b out",  section => 'csv_out' },
            { name => '_file_encoding_out', text => "- File encoding out",  section => 'export'  },
        ],
        group_misc => [
            { name => '_search',      text => "- Search",       section => 'table' },
            { name => '_warnings',    text => "- Warnings",     section => 'G'     },
            { name => 'progress_bar', text => "- Progress bar", section => 'table' },
        ],
        group_global => [
            { name => '_menu_memory', text => "- Menu memory", section => 'G'     },
            { name => '_mouse',       text => "- Mouse mode",  section => 'table' },
        ],
        group_select_plugins => [
            { name => 'plugins', text => "- Select plugins", section => 'G' },
        ],
    };
    if ( $driver eq 'DB2' ) {
        push @{$groups->{group_output}}, { name => '_db2_encoding', text => "- DB2 encoding", section => 'G' };
    }
    return $groups->{$group};
}


sub group_connect {
    my ( $sf, $info, $lo, $section, $sub_group, $driver ) = @_;
    my ( $no, $yes ) = ( 'NO', 'YES' );
    my $sub_menu_required_fields = [
        [ 'host_required', "- Host required",     [ $no, $yes ] ],
        [ 'port_required', "- Port required",     [ $no, $yes ] ],
        [ 'user_required', "- User required",     [ $no, $yes ] ],
        [ 'pass_required', "- Password required", [ $no, $yes ] ],
    ];
    my $items_login_data = [
        { name => 'host', prompt => "- Host" },
        { name => 'port', prompt => "- Port" },
        { name => 'user', prompt => "- User" },
    ];
    my $sub_menu_env_variables = [
        [ 'use_dbi_host', "- Use DBI_HOST", [ $no, $yes ] ],
        [ 'use_dbi_port', "- Use DBI_PORT", [ $no, $yes ] ],
        [ 'use_dbi_user', "- Use DBI_USER", [ $no, $yes ] ],
        [ 'use_dbi_pass', "- Use DBI_PASS", [ $no, $yes ] ],
    ];
    my $items_read_attributes = [
        { name => 'LongReadLen', text => "- LongReadLen" },
    ];
    my $sub_menu_set_attributes = [
        [ 'ChopBlanks',  "- ChopBlanks",  [ $no, $yes ] ],
        [ 'LongTruncOk', "- LongTruncOk", [ $no, $yes ] ],
    ];

    if ( $driver eq 'SQLite' ) {
        $sub_menu_required_fields = [];
        $items_login_data = [];
        $sub_menu_env_variables = [];
        push @$items_read_attributes,
            { name => 'sqlite_busy_timeout', text => "- sqlite_busy_timeout" };
        #my $sqlite_string_mode_values = [
        #    '0 DBD_SQLITE_STRING_MODE_PV',               # 0
        #    '1 DBD_SQLITE_STRING_MODE_BYTES',            # 1
        #    undef,
        #    undef,
        #    '4 DBD_SQLITE_STRING_MODE_UNICODE_NAIVE',    # 4
        #    '5 DBD_SQLITE_STRING_MODE_UNICODE_FALLBACK', # 5
        #    '6 DBD_SQLITE_STRING_MODE_UNICODE_STRICT',   # 6
        #];
        push @$sub_menu_set_attributes,
            #[ 'sqlite_string_mode',         "- sqlite_string_mode",    $sqlite_string_mode_values ],
            [ 'sqlite_string_mode',         "- sqlite_string_mode",         [ 0, 1, undef, undef, 4, 5, 6 ] ], # undef not seen by the user
            [ 'sqlite_see_if_its_a_number', "- sqlite_see_if_its_a_number", [ $no, $yes ] ];
    }
    elsif ( $driver eq 'mysql' ) {
        push @$sub_menu_set_attributes,
            [ 'mysql_enable_utf8',        "- mysql_enable_utf8",        [ $no, $yes ] ],
            [ 'mysql_enable_utf8mb4',     "- mysql_enable_utf8mb4",     [ $no, $yes ] ],
            [ 'mysql_bind_type_guessing', "- mysql_bind_type_guessing", [ $no, $yes ] ];
    }
    elsif ( $driver eq 'MariaDB' ) {
        push @$sub_menu_set_attributes,
            [ 'mariadb_bind_type_guessing', "- mariadb_bind_type_guessing", [ $no, $yes ] ];
    }
    elsif ( $driver eq 'Pg' ) {
        push @$sub_menu_set_attributes,
            [ 'pg_enable_utf8', "- pg_enable_utf8", [ $no, $yes ] ];
    }
    elsif ( $driver eq 'Firebird' ) {
        push @$items_read_attributes,
            { name => 'ib_dialect', text => "- ib_dialect" },
            { name => 'ib_role',    text => "- ib_role" },
            { name => 'ib_charset', text => "- ib_charset" };
        push @$sub_menu_set_attributes,
            [ 'ib_enable_utf8', "- ib_enable_utf8", [ $no, $yes ] ];
    }
    elsif ( $driver eq 'DB2' ) {
        splice( @$sub_menu_required_fields, 0, 2 );
        splice( @$items_login_data, 0, 2 );
        splice( @$sub_menu_env_variables, 0, 2 );
    }
    elsif ( $driver eq 'Informix' ) {
        splice( @$sub_menu_required_fields, 0, 2 );
        splice( @$items_login_data, 0, 2 );
        splice( @$sub_menu_env_variables, 0, 2 );
        push @$sub_menu_set_attributes,
            [ 'ix_EnableUTF8', "- ix_EnableUTF8", [ $no, $yes ] ];
    }
    elsif ( $driver eq 'Oracle' ) {
        push @$items_read_attributes,
            { name => 'ora_charset', text => "- ora_charset" };
        push @$sub_menu_set_attributes,
            [ 'AskIfSID', "- AskIfSID", [ $no, $yes ] ];
    }
    elsif ( $driver eq 'ODBC' ) {
        splice( @$sub_menu_required_fields, 0, 2 );
        splice( @$items_login_data, 0, 2 );
        splice( @$sub_menu_env_variables, 0, 2 );
        push @$items_read_attributes,
            { name => 'odbc_batch_size', text => "- odbc_batch_size" };
        push @$sub_menu_set_attributes,
            [ 'odbc_utf8_on',                   "- odbc_utf8_on",                   [ $no, $yes ] ],
            [ 'odbc_ignore_named_placeholders', "- odbc_ignore_named_placeholders", [ $no, $yes ] ],
            #[ 'odbc_array_operations',          "- odbc_array_operations",          [ $no, $yes ] ];
    }
    elsif ( $driver eq 'DuckDB' ) {
        $sub_menu_required_fields = [];
        $items_login_data = [];
        $sub_menu_env_variables = [];
    }
    if ( $sub_group eq '_required_fields' ) {
        my $prompt = 'Required Fields:';
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu_required_fields, $prompt );
    }
    elsif ( $sub_group eq '_login_data' ) {
        my $prompt = 'Login Data:';
        $sf->__group_readline( $info, $lo, $section, $items_login_data, $prompt );
    }
    elsif ( $sub_group eq '_env_variables' ) {
        my $prompt = 'Environment Variables:';
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu_env_variables, $prompt );
    }
    elsif ( $sub_group eq '_read_attributes' ) {
        my $prompt = 'Read Attributes:';
        $sf->__group_readline( $info, $lo, $section, $items_read_attributes, $prompt );
    }
    elsif ( $sub_group eq '_set_attributes' ) {
        my $prompt = 'Set Attributes:';
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu_set_attributes, $prompt );
    }
    else {
        die "connect: unknown sub_group $sub_group";
    }
    return;
}


sub group_extensions {
    my ( $sf, $info, $lo, $section, $sub_group ) = @_;
    my ( $no, $yes ) = ( 'NO', 'YES' );
    if ( $sub_group eq '_e_table' ) {
        my $prompt = 'Extend tables menu:';
        my $sub_menu = [
            [ 'm_derived',   "- Add subquery",    [ $no, $yes ] ],
            [ 'm_cte',       "- Add cte",         [ $no, $yes ] ],
            [ 'join',        "- Add join",        [ $no, $yes ] ],
            [ 'union',       "- Add union",       [ $no, $yes ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_e_join' ) {
        my $prompt = 'Extend join menu:';
        my $sub_menu = [
            [ 'j_derived', "- Add subquery", [ $no, $yes ] ],
            [ 'j_cte',     "- Add cte",      [ $no, $yes ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_e_union' ) {
        my $prompt = 'Extend union menu:';
        my $sub_menu = [
            [ 'u_derived',     "- Add subquery",   [ $no, $yes ] ],
            [ 'u_cte',         "- Add cte",        [ $no, $yes ] ],
            [ 'u_edit_stmt',   "- Edit statement", [ $no, $yes ] ],
            [ 'u_parentheses', "- Parentheses",    [ $no, $yes ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_e_expressions' ) {
        my $prompt = 'Extended expressions:';
        my $sub_menu = [
            [ 'extended_cols',   "- Exdented columns",    [ $no, $yes ] ],
            [ 'extended_values', "- Exdented values",     [ $no, $yes ] ],
            [ 'extended_args',   "- Exdented arguments",  [ $no, $yes ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_e_write_access' ) {
        my $prompt = 'Write access: ';
        my $sub_menu = [
            [ 'insert_into',  "- Insert records", [ $no, $yes ] ],
            [ 'update',       "- Update records", [ $no, $yes ] ],
            [ 'delete',       "- Delete records", [ $no, $yes ] ],
            [ 'create_table', "- Create table",   [ $no, $yes ] ],
            [ 'drop_table',   "- Drop   table",   [ $no, $yes ] ],
            [ 'create_view',  "- Create view",    [ $no, $yes ] ],
            [ 'drop_view',    "- Drop   view",    [ $no, $yes ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    else {
        die "extensions: unknown sub_group $sub_group";
    }
    return;
}


sub group_sql_settings {
    my ( $sf, $info, $lo, $section, $sub_group, $driver ) = @_;
    my ( $no, $yes ) = ( 'NO', 'YES' );
    if ( $sub_group eq '_meta' ) {
        my $prompt = 'System data ';
        my $sub_menu = [
            [ 'metadata', "- Show system DB/schemas/tables", [ $no, $yes ] ]
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq 'operators' ) {
        my $prompt = 'Choose operators';
        my $avail_operators = [
            " = ", " != ", " <> ", " < ", " > ", " >= ", " <= ",
            "REGEXP", "REGEXP_i", "NOT REGEXP", "NOT REGEXP_i", "LIKE", "NOT LIKE",
            "IS NULL", "IS NOT NULL", "IN", "NOT IN", "BETWEEN", "NOT BETWEEN",
            "ANY", "ALL",
        ];
        $sf->__choose_a_subset_wrap( $info, $lo, $section, $sub_group, $avail_operators, $prompt );
    }
    elsif ( $sub_group eq '_add_aliases' ) {
        my $prompt = 'Add alias:';
        my $sub_menu = [
            [ 'complex_cols_select', "- Functions/Subqueries in select",  [ 'NO',   undef, 'ASK',   undef     ] ],
            [ 'tables_in_join',      "- Tables in join",                  [ undef, 'AUTO',  undef, 'ASK/AUTO' ] ],
            [ 'join_columns',        "- Non-unique columns in join",      [ 'NO',  'AUTO', 'ASK',  'ASK/AUTO' ] ],
            [ 'derived_table',       "- Derived table",                   [ 'NO',  'AUTO', 'ASK',  'ASK/AUTO' ] ],
            [ 'ordinary_table',      "- Ordinary table",                  [ 'NO',  'AUTO', 'ASK',  'ASK/AUTO' ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_aliases_in_clauses' ) {
        my $prompt = 'Use aliases in: ';
        my $sub_menu = [
            [ 'use_in_group_by', "- Group by", [ $no, $yes ] ],
            [ 'use_in_having',   "- Having",   [ $no, $yes ] ],
            [ 'use_in_order_by', "- Order by", [ $no, $yes ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_sql_identifiers' ) {
        my $prompt = 'Your choice: ';
        my $sub_menu = [
            [ 'qualified_table_name', "- Qualified table names", [ $no, $yes ] ],
            [ 'quote_tables',         "- Quote table names",     [ $no, $yes ] ],
            [ 'quote_columns',        "- Quote column names",    [ $no, $yes ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_view_name_prefix' ) {
        my $items = [
            { name => 'view_name_prefix', prompt => "View name prefix" },
        ];
        my $prompt = 'Set a view name prefix';
        $sf->__group_readline( $info, $lo, $section, $items, $prompt );
    }
    elsif ( $sub_group eq '_other_sql_settings' ) {
        my $prompt = 'Your choice: ';
        my $sub_menu = [
            [ 'edit_sql_menu_sq', "- Subqueries created with 'SQL Menu': Allow editing.", [ $no, $yes ] ],
        ];
        if ( $driver eq 'Pg' ) {
            push @$sub_menu, [ 'pg_autocast', "- Pg: Convert to 'text' automatically when required.", [ $no, $yes ] ];
        }
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    else {
        die "sql_settings: unknown sub_group $sub_group";
    }
    return;
}


sub group_create_table {
    my ( $sf, $info, $lo, $section, $sub_group ) = @_;
    my ( $no, $yes ) = ( 'NO', 'YES' );
    if ( $sub_group eq '_enable_ct_opt' ) {
        my $prompt = 'Activate options';
        my $sub_menu = [
            [ 'option_ai_column_enabled',       "- Offer auto increment column",   [ $no, $yes ] ],
            [ 'data_type_guessing',             "- Data type guessing",            [ $no, $yes ] ],
            [ 'encode_for_data_type_guessing',  "- Encode for data type guessing", [ $no, $yes ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_add_ct_fields' ) {
        my $prompt = 'Add fields';
        my $sub_menu = [
            [ 'table_constraint_rows', "- Table constraint fields", [ 0 .. 9    ] ],
            [ 'table_option_rows',     "- Table option fields",     [ 0 .. 9    ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_default_ai_column_name' ) {
        my $items = [
            { name => 'default_ai_column_name', prompt => "Default primary key auto increment column name" },
        ];
        my $prompt = 'Set a default auto increment column name';
        $sf->__group_readline( $info, $lo, $section, $items, $prompt );
    }
    else {
        die "create_table: unknown sub_group $sub_group";
    }
    return;
}


sub group_output {
    my ( $sf, $info, $lo, $section, $sub_group ) = @_;
    my ( $no, $yes ) = ( 'NO', 'YES' );
    if ( $sub_group eq '_binary_filter' ) {
        my $prompt = 'How to print arbitrary binray data';
        my $sub_menu = [
            [ 'binary_filter', "- Binary filter", [ $no, 'BNRY', 'Hexadecimal' ] ]
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_squash_spaces' ) {
        my $prompt = 'Remove leading and trailing spaces and squash consecutive spaces';
        my $sub_menu = [
            [ 'squash_spaces', "- Squash spaces", [ $no, $yes ] ]
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_set_string' ) {
        my $items = [
            { name => 'undef', prompt => "Show undefined fields as" },
        ];
        my $prompt = 'Undef string';
        $sf->__group_readline( $info, $lo, $section, $items, $prompt );
    }
    elsif ( $sub_group eq '_color' ) {
        my $prompt = '"ANSI color escapes"';
        my $sub_menu = [
            [ 'color', "- ANSI color escapes", [ $no, $yes ] ]
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq 'trunc_fract_first' ) {
        my $prompt = 'If the terminal is not wide enough:';
        my $sub_menu = [
            [ 'trunc_fract_first', "- First step: truncate fraction of numbers", [ $no, $yes ] ]
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_base_indent' ) {
        my $prompt = 'Set the indentation width for SQL substatements';
        my $sub_menu = [
            [ 'base_indent', "- Indentation", [ 0, 1, 2, 3, 4 ] ]
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq 'tab_width' ) {
        my $digits = 3;
        my $prompt = 'Set the tab width ';
        $sf->__choose_a_number_wrap( $info, $lo, $section, $sub_group, $prompt, $digits, 0 );
    }
    elsif ( $sub_group eq '_pad_row_edges' ) {
        my $prompt = '"Pad row edges"';
        my $sub_menu = [
            [ 'pad_row_edges', "- Pad row edges with a space.", [ $no, $yes ] ]
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_expand_rows' ) {
        my $prompt = 'Your choice: ';
        my $sub_menu = [
            [ 'table_expand', "- Expand table rows",   [ $no, $yes ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq 'max_width_exp' ) {
        my $digits = 3;
        my $prompt = 'Maximum width of expanded table rows';
        $sf->__choose_a_number_wrap( $info, $lo, $section, $sub_group, $prompt, $digits, 0 );
    }
    elsif ( $sub_group eq 'min_col_width' ) {
        my $digits = 3;
        my $prompt = 'Set the minimum column width ';
        $sf->__choose_a_number_wrap( $info, $lo, $section, $sub_group, $prompt, $digits, 0 );
    }
    elsif ( $sub_group eq '_db2_encoding' ) {
        my $items = [
            { name => 'db2_encoding', prompt => "DB2 application code set" },
        ];
        my $prompt = 'Set the DB2 application code set';
        $sf->__group_readline( $info, $lo, $section, $items, $prompt );
    }
    else {
        die "output: unknown sub_group $sub_group";
    }
    return;
}


sub group_import {
    my ( $sf, $info, $lo, $section, $sub_group ) = @_;
    my ( $no, $yes ) = ( 'NO', 'YES' );
    if ( $sub_group eq '_data_source_type' ) {
        my $prompt = 'Data source options';
        my $sub_menu = [
            [ 'data_source_create_table', "- Data source \"Create table\"", [ 'plain', 'file', 'menu' ], ],
            [ 'data_source_insert',       "- Data source \"Insert into\"",  [ 'plain', 'file', 'menu' ], ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_parse_file' ) {
        my $prompt = 'How to parse input files';
        my $sub_menu = [
            [ 'parse_mode_input_file', "- Use", [ 'Text::CSV', 'split', 'Template', 'Spreadsheet::Read' ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_csv_in_char' ) {
        my $items = [
            { name => 'sep_char',    prompt => "sep_char   " },
            { name => 'quote_char',  prompt => "quote_char " },
            { name => 'escape_char', prompt => "escape_char" },
            { name => 'eol',         prompt => "eol        " },
            { name => 'comment_str', prompt => "comment_str" },
        ];
        my $prompt = 'Text::CSV_XS options a';
        $sf->__group_readline( $info, $lo, $section, $items, $prompt );
    }
    elsif ( $sub_group eq '_csv_in_options' ) {
        my $prompt = 'Text::CSV_XS options b';
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
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_split_config' ) {
        my $items = [
            { name => 'field_sep',     prompt => "Field separator  " },
            { name => 'field_l_trim',  prompt => "Trim field left  " },
            { name => 'field_r_trim',  prompt => "Trim field right " },
            { name => 'record_sep',    prompt => "Record separator " },
            { name => 'record_l_trim', prompt => "Trim record left " },
            { name => 'record_r_trim', prompt => "Trim record right" },
        ];
        my $prompt = 'Config \'split\' mode';
        $sf->__group_readline( $info, $lo, $section, $items, $prompt );
    }
    elsif ( $sub_group eq '_input_filter' ) {
        my $prompt = 'Enable input filter';
        my $sub_menu = [
            [ 'enable_input_filter', "- Enable input filter", [ $no, $yes ] ]
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_empty_to_null' ) {
        my $prompt = 'Enable "Empty to NULL":';
        my $sub_menu = [
            [ 'empty_to_null_plain',  "- Source type 'plain'",  [ $no, $yes ] ],
            [ 'empty_to_null_file',   "- Source type 'file'",   [ $no, $yes ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_file_encoding_in' ) {
        my $items = [
            { name => 'file_encoding', prompt => "Input file encoding" },
        ];
        my $prompt = 'Encoding of input data text files';
        $sf->__group_readline( $info, $lo, $section, $items, $prompt );
    }
    elsif ( $sub_group eq 'history_dirs' ) {
        my $digits = 2;
        my $prompt = 'Number of saved dirs: ';
        $sf->__choose_a_number_wrap( $info, $lo, $section, $sub_group, $prompt, $digits, 1 );
    }
    elsif ( $sub_group eq '_file_filter' ) {
        my $items = [
            { name => 'file_filter', prompt => "File filter glob pattern" },
        ];
        my $prompt = 'Set the glob pattern for the file filter';
        $sf->__group_readline( $info, $lo, $section, $items, $prompt );
    }
    elsif ( $sub_group eq '_show_hidden_files' ) {
        my $prompt = 'Show hidden files';
        my $sub_menu = [
            [ 'show_hidden_files', "- Show hidden files", [ $no, $yes ] ]
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    else {
        die "import: unknown sub_group $sub_group";
    }
    return;
}


sub group_export {
    my ( $sf, $info, $lo, $section, $sub_group ) = @_;
    my ( $no, $yes ) = ( 'NO', 'YES' );
    if ( $sub_group eq 'export_dir' ) {
        my $prompt = 'Select the destination folder for data exported as CSV files.';
        $sf->__choose_a_directory_wrap( $info, $lo, $section, $sub_group, $prompt );
    }
    elsif ( $sub_group eq '_exported_files' ) {
        my $prompt = 'Data export to CSV files';
        my $sub_menu = [
            [ 'add_extension',      "- Add automatically '.csv'-extension", [ $no, $yes ] ],
            [ 'default_filename',   "- Table name is default file name",    [ $no, $yes ] ]
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_file_encoding_out' ) {
        my $items = [
            { name => 'file_encoding', prompt => "Encoding CSV file" },
        ];
        my $prompt = 'Data to CSV-files';
        $sf->__group_readline( $info, $lo, $section, $items, $prompt );
    }
    elsif ( $sub_group eq '_csv_out_char' ) {
        my $items = [
            { name => 'sep_char',    prompt => "sep_char   " },
            { name => 'quote_char',  prompt => "quote_char " },
            { name => 'escape_char', prompt => "escape_char" },
            { name => 'eol',         prompt => "eol        " },
            { name => 'undef_str',   prompt => "undef_str"   },
        ];
        my $prompt = 'Text::CSV_XS write options a';
        $sf->__group_readline( $info, $lo, $section, $items, $prompt );
    }
    elsif ( $sub_group eq '_csv_out_options' ) {
        my $prompt = 'Text::CSV_XS write options b';
        my $sub_menu = [
            [ 'always_quote', "- always_quote", [ $no, $yes ] ],
            [ 'binary',       "- binary",       [ $no, $yes ] ],
            [ 'escape_null',  "- escape_null",  [ $no, $yes ] ],
            [ 'quote_binary', "- quote_binary", [ $no, $yes ] ],
            [ 'quote_empty',  "- quote_empty",  [ $no, $yes ] ],
            [ 'quote_space',  "- quote_space",  [ $no, $yes ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    else {
        die "export: unknown sub_group $sub_group";
    }
    return;
}


sub group_misc {
    my ( $sf, $info, $lo, $section, $sub_group, $driver ) = @_;
    my ( $no, $yes ) = ( 'NO', 'YES' );
    if ( $sub_group eq '_search' ) {
        my $prompt = 'Your choice: ';
        my $sub_menu = [
            [ 'search', "- Row filter", [ 'disabled', 'case insensitive', 'case sensitive' ] ]
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_warnings' ) {
        my $prompt = '"Disable/Enable warnings"';
        my $sub_menu = [
            [ 'warnings_table_print', "- Warnings table-print", [ $no, $yes ] ],
        ];
        if ( $driver eq 'SQLite' ) {
            push @$sub_menu, [ 'file_find_warnings', "- Warnings \"File::Find\" search", [ $no, $yes ] ];
        }
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq 'progress_bar' ) {
        my $digits = 7;
        my $prompt = 'Set the threshold for the progress bar ';
        $sf->__choose_a_number_wrap( $info, $lo, $section, $sub_group, $prompt, $digits, 0 );
    }
    else {
        die "misc: unknown sub_group: $sub_group";
    }
    return;
}


sub group_global {
    my ( $sf, $info, $lo, $section, $sub_group ) = @_;
    my ( $no, $yes ) = ( 'NO', 'YES' );
    if ( $sub_group eq '_menu_memory' ) {
        my $prompt = 'Your choice: ';
        my $sub_menu = [
            [ 'menu_memory', "- Menu memory", [ $no, $yes ] ],
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    elsif ( $sub_group eq '_mouse' ) {
        my $prompt = 'Your choice: ';
        my $sub_menu = [
            [ 'mouse', "- Mouse mode", [ $no, $yes ] ]
        ];
        $sf->__settings_menu_wrap( $info, $lo, $section, $sub_menu, $prompt );
    }
    else {
        die "global: unknown sub_group: $sub_group";
    }
    return;
}


sub group_select_plugins {
    my ( $sf, $info, $lo, $section, $sub_group ) = @_;
    if ( $sub_group eq 'plugins' ) {
        my %installed_plugins;

        for my $dir ( @INC ) {
            my $glob_pattern = catfile $dir, 'App', 'DBBrowser', 'DB', '*.pm';
            map { $installed_plugins{( fileparse $_, '.pm' )[0]}++ } glob $glob_pattern;
        }
        my $avail_plugins = [ sort keys %installed_plugins ];
        my $prompt = 'Select plugins';
      #  $info = undef;
        $sf->__choose_a_subset_wrap( $info, $lo, $section, $sub_group, $avail_plugins, $prompt );
    }
    else {
        die "global: unknown sub_group: $sub_group";
    }
    return;
}


sub __settings_menu_wrap {
    # sets the options to the index of the chosen values, not to the values itself
    my ( $sf, $info, $lo, $section, $sub_menu, $prompt ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $changed = $tu->settings_menu(
        $sub_menu, $lo->{$section},
        { info => $info, prompt => $prompt, back => $sf->{i}{_back}, confirm => $sf->{i}{_confirm} }
    );
}


sub __choose_a_subset_wrap {
    my ( $sf, $info, $lo, $section, $opt, $available, $prompt ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $current = $lo->{$section}{$opt};
    $info .= "\n" if length $info;
    $info .= 'Cur: ' . join( ', ', @$current );
    my $name = 'New: ';
    # Choose_a_list
    my $list = $tu->choose_a_subset(
        $available,
        { info => $info, prompt => $prompt, cs_label => $name, prefix => '- ', keep_chosen => 0,
          index => 0, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back}, layout => 2,
          clear_screen => 1 }
    );
    return if ! defined $list;
    return if ! @$list;
    $lo->{$section}{$opt} = $list;
    return;
}


sub __choose_a_number_wrap {
    my ( $sf, $info, $lo, $section, $opt, $prompt, $digits, $small_first ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $current = $lo->{$section}{$opt};
    my $w = $digits + int( ( $digits - 1 ) / 3 ) * length $sf->{i}{info_thsd_sep};
    $info .= "\n" . 'Cur: ' . sprintf( "%*s", $w, insert_sep( $current, $sf->{i}{info_thsd_sep} ) );
    my $name = 'New: ';
    # Choose_a_number
    my $choice = $tu->choose_a_number( $digits,
        { info => $info, prompt => $prompt, cs_label => $name, small_first => $small_first,
          clear_screen => 1, confirm => $sf->{i}{confirm}, back => $sf->{i}{back} }
    );
    return if ! defined $choice;
    $lo->{$section}{$opt} = $choice;
    return;
}


sub __choose_a_directory_wrap {
    my ( $sf, $info, $lo, $section, $opt, $prompt ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    #my $current = $lo->{$section}{$opt};
    # Choose_a_directory
    my $choice = $tu->choose_a_directory(
        { show_hidden => 1, info => $info, prompt => $prompt, clear_screen => 1, decoded => 1,
          confirm => $sf->{i}{confirm}, back => $sf->{i}{back} } ##
    );
    return if ! defined $choice;
    $lo->{$section}{$opt} = $choice;
    return;
}


sub __group_readline {
    my ( $sf, $info, $lo, $section, $items, $prompt ) = @_;
    my $list = [ map {
        [ exists $_->{prompt} ? $_->{prompt} : $_->{name}, $lo->{$section}{$_->{name}} ]
    } @{$items} ];
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    # Fill_Form
    my $new_list = $tf->fill_form(
        $list,
        { info => $info, prompt => $prompt, confirm => $sf->{i}{confirm}, back => $sf->{i}{back} }
    );
    if ( $new_list ) {
        for my $i ( 0 .. $#$items ) {
            $lo->{$section}{$items->[$i]{name}} = $new_list->[$i][1];
        }
    }
}



1;


__END__
