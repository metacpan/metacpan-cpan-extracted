package # hide from PAUSE
App::DBBrowser::Options::Defaults;

use warnings;
use strict;
use 5.016;

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options ) = @_;
    bless {
        i => $info,
        o => $options,
    }, $class;
}



sub defaults_pre_plugin {
    my ( $sf ) = @_;
    my $defaults_pre_plugin = {
        G => {
            menu_memory => 1,
            plugins     => [ 'SQLite' ],
        },
        table => {
            mouse => 0,
        },
        # could be more
    };
    return $defaults_pre_plugin;
}



sub defaults {
    my ( $sf, $driver ) = @_;
    my $defaults = {
        G => {
            base_indent           => 1,
            file_find_warnings    => 0,
            warnings_table_print  => 1,
            metadata              => 0,
            operators             => [ " = ", " != ", " < ", " > ", "REGEXP_i", "NOT REGEXP_i", "IS NULL", "IS NOT NULL", "IN", "NOT IN" ],

            qualified_table_name  => 0,
            quote_tables          => 0,
            quote_columns         => 0,

            edit_sql_menu_sq      => 0, ##
            pg_autocast           => 1,

            db2_encoding          => 'utf8',
            duckdb_decode_db_out  => 0,
        },
        alias => {
            complex_cols_select => 0,
            tables_in_join      => 1,
            join_columns        => 0,
            derived_table       => 1,
            ordinary_table      => 0,

            use_in_group_by     => 0,       # if SQLite, MySQL, MariaDB, Pg, Firebird, Informix, Oracle >= 23ai
            use_in_having       => 0,       # if SQLite, MySQL, MariaDB, Oracle >= 23ai
            use_in_order_by     => 1,
        },
        enable => {
            create_table => 0,
            drop_table   => 0,
            create_view  => 0,
            drop_view    => 0,

            insert_into => 0,
            update      => 0,
            delete      => 0,

            extended_cols   => 0,
            extended_values => 0,
            extended_args   => 0,

            m_derived   => 0,
            m_cte       => 0,

            join        => 0,
            union       => 0,

            j_derived  => 0,
            j_cte      => 0,

            u_derived     => 0,
            u_cte         => 0,
            u_edit_stmt   => 0,
            u_parentheses => 0,
        },
        table => {
            codepage_mapping  => 0, # not an option, always 0
            hide_cursor       => 0, # not an option, always 0
            max_rows          => 0, # not an option, always 0
            page              => 2, # not an option, always 2

            binary_filter     => 0,
            binary_string     => 'BNRY',
            color             => 0,
            max_width_exp     => 0,
            min_col_width     => 30,
#            mouse             => 0,
            pad_row_edges     => 0,
            progress_bar      => 60_000,
            search            => 1,
            squash_spaces     => 0,
            tab_width         => 2,
            table_expand      => 1, # expand_table_rows ##
            trunc_fract_first => 1,
            undef             => '',
        },
        insert => {
            file_encoding            => 'UTF-8',
            history_dirs             => 4,
            parse_mode_input_file    => 0,
            enable_input_filter      => 1,
            empty_to_null_plain      => 1,
            empty_to_null_file       => 1,
            data_source_create_table => 2,
            data_source_insert       => 2,
            show_hidden_files        => 0,
            file_filter              => '',
        },
        create => {
            default_ai_column_name         => 'Id',
            option_ai_column_enabled       => 0,
            data_type_guessing             => 1,
            encode_for_data_type_guessing  => 0,
            table_constraint_rows          => 0,
            table_option_rows              => 0,
            view_name_prefix               => '',
        },
        split => {
            record_sep    => '\n',
            record_l_trim => '',
            record_r_trim => '',
            field_sep     => ',',
            field_l_trim  => '\s+',
            field_r_trim  => '\s+',
        },
        csv_in => {
            auto_diag => 1,  # not an option, always 1

            sep_char    => ',',
            quote_char  => '"',
            escape_char => '"',
            eol         => '',
            comment_str => '',

            allow_loose_escapes => 0,
            allow_loose_quotes  => 0,
            allow_whitespace    => 0,
            blank_is_undef      => 1,
            binary              => 1,
            decode_utf8         => 1,
            empty_is_undef      => 0,
            skip_empty_rows     => 0,
        },
        export => {
            export_dir       => $sf->{i}{home_dir},
            add_extension    => 0,
            default_filename => 0,
            file_encoding    => 'UTF-8',
        },
        csv_out => {
            auto_diag => 1,  # not an option, always 1

            sep_char    => ',',
            quote_char  => '"',
            escape_char => '"',
            eol         => '',
            undef_str   => '',

            always_quote => 0,
            binary       => 1,
            escape_null  => 1,
            quote_binary => 1,
            quote_empty  => 0,
            quote_space  => 1,
        },
        connect_data => {
            host_required => 1,
            port_required => 1,
            user_required => 1,
            pass_required => 1,
            host => '',
            port => '',
            user => '',
            use_dbi_host => 0,
            use_dbi_port => 0,
            use_dbi_user => 0,
            use_dbi_pass => 0,
        },
        connect_attr => {
            ChopBlanks  => 0,
            LongTruncOk => 0,
            LongReadLen => 80,
        },
    };
    if ( $driver eq 'SQLite' ) {
        $defaults->{connect_attr}{sqlite_see_if_its_a_number} = 1;
        $defaults->{connect_attr}{sqlite_string_mode}         = 5;
        $defaults->{connect_attr}{sqlite_busy_timeout}        = 30000;
    }
    elsif ( $driver eq 'mysql' ) {
        $defaults->{connect_attr}{mysql_enable_utf8}        = 0;
        $defaults->{connect_attr}{mysql_enable_utf8mb4}     = 1;
        $defaults->{connect_attr}{mysql_bind_type_guessing} = 1;
    }
    elsif ( $driver eq 'MariaDB' ) {
        $defaults->{connect_attr}{mariadb_bind_type_guessing} = 1;
    }
    elsif ( $driver eq 'Pg' ) {
        $defaults->{connect_attr}{pg_enable_utf8} = -1;
    }
    elsif ( $driver eq 'Firebird' ) {
        $defaults->{connect_attr}{ib_enable_utf8} = 1;
        $defaults->{connect_attr}{ib_dialect}     = '';
        $defaults->{connect_attr}{ib_role}        = '';
        $defaults->{connect_attr}{ib_charset}     = 'UTF8';
    }
    elsif ( $driver eq 'Oracle' ) {
        $defaults->{connect_attr}{ora_charset} = 'AL32UTF8';
        $defaults->{connect_attr}{AskIfSID}    = 0;
    }
    elsif ( $driver eq 'DB2' ) {
    }
    elsif ( $driver eq 'Informix' ) {
        $defaults->{connect_attr}{ix_EnableUTF8} = 1;
    }
    elsif ( $driver eq 'ODBC' ) {
        $defaults->{connect_attr}{odbc_utf8_on}                   = 0;
        $defaults->{connect_attr}{odbc_ignore_named_placeholders} = 0;
       #$defaults->{connect_attr}{odbc_array_operations}          = 0;
        $defaults->{connect_attr}{odbc_batch_size}                = 10;
    }
    elsif ( $driver eq 'DuckDB' ) {
    }
    return $defaults;
}





1;


__END__
