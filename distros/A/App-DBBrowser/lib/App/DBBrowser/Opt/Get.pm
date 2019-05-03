package # hide from PAUSE
App::DBBrowser::Opt::Get;

use warnings;
use strict;
use 5.010001;

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
            info_expand          => 0,
            max_rows             => 200_000,
            menu_memory          => 1,
            metadata             => 0,
            operators            => [ "REGEXP", "REGEXP_i", " = ", " != ", " < ", " > ", "IS NULL", "IS NOT NULL" ],
            plugins              => [ 'SQLite', 'mysql', 'Pg' ],
            qualified_table_name => 0,
            quote_identifiers    => 1,
            thsd_sep             => ',',
            file_find_warnings   => 0,
        },
        alias => {
            aggregate  => 0,
            functions  => 0,
            join       => 0,
            union      => 0,
            subqueries => 0,
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
            color             => 0,
            decimal_separator => '.',
            grid              => 1,
            keep_header       => 1,
            min_col_width     => 30,
            mouse             => 0,
            progress_bar      => 40_000,
            squash_spaces     => 0,
            tab_width         => 2,
            table_expand      => 1,
            undef             => '',
        },
        insert => {
            copy_parse_mode => 1,
            file_encoding   => 'UTF-8',
            file_parse_mode => 0,
            history_dirs    => 4,
        },
        create => {
            autoincrement_col_name => 'Id',
            data_type_guessing     => 1,
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
        }
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
        my $tmp = $ax->read_json( $file_fs );
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
