package # hide from PAUSE
App::DBBrowser::Opt::Get;

use warnings;
use strict;
use 5.014;

use App::DBBrowser::Auxil;


sub new {
    my ( $class, $info, $options ) = @_;
    bless {
        i => $info,
        o => $options,
    }, $class;
}


sub defaults {
    my ( $sf, $section, $key ) = @_;
    my $defaults = {
        G => {
            auto_limit           => 0,
            menu_memory          => 1,
            metadata             => 0,
            operators            => [ "REGEXP", "REGEXP_i", " = ", " != ", " < ", " > ", "IS NULL", "IS NOT NULL" ],
            plugins              => [ 'SQLite', 'mysql', 'Pg', 'Firebird' ],
            qualified_table_name => 0,
            quote_identifiers    => 1,
            thsd_sep             => ',',
            base_indent          => 1,
            file_find_warnings   => 0,
            round_precision_sign => 0,
        },
        alias => {
            select        => 0,
            aggregate     => 0,
            derived_table => 0,
            join          => 0,
            union         => 0,
        },
        enable => {
            create_table => 0,
            drop_table   => 0,
            create_view  => 0,
            drop_view    => 0,

            insert_into => 0,
            update      => 0,
            delete      => 0,

            expand_select   => 0,
            expand_where    => 0,
            expand_group_by => 0,
            expand_having   => 0,
            expand_order_by => 0,
            expand_set      => 0,

            parentheses => 0,

            m_derived   => 0,
            join        => 0,
            union       => 0,
            db_settings => 0,

            j_derived  => 0,

            u_derived => 0,
            union_all => 0,
        },
        table => {
            binary_filter     => 0,
            binary_string     => 'BNRY',
            codepage_mapping  => 0, # not an option, always 0
            hide_cursor       => 0, # not an option, always 0
            page              => 2, # not an option, always 2
            color             => 0,
            decimal_separator => '.',
            min_col_width     => 30,
            mouse             => 0,
            progress_bar      => 40_000,
            search            => 1,
            squash_spaces     => 0,
            tab_width         => 2,
            table_expand      => 1,
            trunc_fract_first => 1,
            undef             => '',
        },
        insert => {
            file_encoding            => 'UTF-8',
            history_dirs             => 4,
            parse_mode_input_file    => 0,
            enable_input_filter      => 0,
            empty_to_null_plain      => 1,
            empty_to_null_file       => 0,
            data_source_Create_table => 2,
            data_source_Insert       => 2,
            show_hidden_files        => 0,
            file_filter              => '',
        },
        create => {
            autoincrement_col_name => 'Id',
            data_type_guessing     => 1,
            view_name_prefix       => '',
        },
        split => {
            record_sep    => '\n',
            record_l_trim => '',
            record_r_trim => '',
            field_sep     => ',',
            field_l_trim  => '\s+',
            field_r_trim  => '\s+',
        },
        csv => {
            sep_char            => ',',
            quote_char          => '"',
            escape_char         => '"',
            eol                 => '',

            allow_loose_escapes => 0,
            allow_loose_quotes  => 0,
            allow_whitespace    => 0,
            auto_diag           => 1,
            blank_is_undef      => 1,
            binary              => 1,
            empty_is_undef      => 0,
        },
        export => {
            export_dir      => $sf->{i}{home_dir},
            add_extension   => 0,
            export_encoding => 'UTF-8',
        },
    };
    return $defaults                   if ! $section;
    return $defaults->{$section}       if ! $key;
    return $defaults->{$section}{$key};
}


sub read_config_files {
    my ( $sf ) = @_;
    my $o = $sf->defaults();
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, {} );
    my $file_fs = $sf->{i}{f_settings};
    if ( -f $file_fs && -s $file_fs ) {
        my $tmp = $ax->read_json( $file_fs ) // {};
        for my $section ( keys %$tmp ) {
            for my $opt ( keys %{$tmp->{$section}} ) {
                $o->{$section}{$opt} = $tmp->{$section}{$opt} if exists $o->{$section}{$opt};
            }
        }
    }
    return $o;
}




1;


__END__
