package # hide from PAUSE
App::DBBrowser::Opt;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '2.001';

use File::Basename        qw( fileparse );
use File::Spec::Functions qw( catfile );
use FindBin               qw( $RealBin $RealScript );
#use Pod::Usage            qw( pod2usage );  # "require"-d

use Term::Choose       qw( choose );
use Term::Choose::Util qw( insert_sep print_hash choose_a_number choose_a_subset settings_menu choose_a_dir );
use Term::Form         qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::OptDB;


sub new {
    my ( $class, $info, $opt ) = @_;
    bless { i => $info, o => $opt }, $class;
}


sub defaults {
    my ( $sf, $section, $key ) = @_;
    my $defaults = {
        G => {
            plugins              => [ 'SQLite', 'mysql', 'Pg' ],
            menu_memory          => 0,
            thsd_sep             => ',', ###
            max_rows             => 50_000,
            meta                 => 0,
            lock_stmt            => 0,
            operators            => [ "REGEXP", "REGEXP_i", " = ", " != ", " < ", " > ", "IS NULL", "IS NOT NULL" ],
            parentheses_w        => 0,
            parentheses_h        => 0,
            quote_identifiers    => 1,
            qualified_table_name => 0,
        },
        table => {
            table_expand         => 1,
            mouse                => 0,
            keep_header          => 0,
            progress_bar         => 40_000,
            min_col_width        => 30,
            tab_width            => 2,
            grid                 => 0,
            undef                => '',
            binary_string        => 'BNRY',
            binary_filter        => 0,
        },
        insert => {
        # Input
            #input_modes          => [ 'Cols', 'Rows', 'Multi-row', 'File' ],
            files_dir            => undef,
            file_encoding        => 'UTF-8',
            max_files            => 15,
        # Parsing
            #_parse_mode
            file_parse_mode      => 0,
            copy_parse_mode      => 1,
        # create table defaults:
#            id_col_name          => 'ID_a',
            default_data_type    => 'TEXT',
        },
        split => {
            i_r_s                => '\n',
            i_f_s                => ',',
        },
        csv => {
            sep_char             => ',',
            quote_char           => '"',
            escape_char          => '"',
            eol                  => '',
            allow_loose_escapes  => 0,
            allow_loose_quotes   => 0,
            allow_whitespace     => 0,
            auto_diag            => 1,
            blank_is_undef       => 1,
            binary               => 1,
            empty_is_undef       => 0,
        }
    };
    return $defaults                   if ! $section;
    return $defaults->{$section}       if ! $key;
    return $defaults->{$section}{$key};
}


sub __menu_insert {
    my ( $sf, $group ) = @_;
    my $menu_insert = {
        main_insert => [
#            { name => 'input_modes',           text => "- Read",           section => 'insert' },
            { name => 'files_dir',             text => "- File Dir",         section => 'insert' },
            { name => 'file_encoding',         text => "- File Encoding",    section => 'insert' },
            { name => 'max_files',             text => "- File History",     section => 'insert' },
            { name => '_parse_mode',           text => "- Parse-mode",       section => 'insert' },
            { name => '_module_Text_CSV',      text => "- config Text::CSV", section => 'csv'    },
            { name => '_parse_with_split',     text => "- config 'split'",   section => 'split'  },
            { name => 'create_table_defaults', text => "- Create-table",     section => 'insert' },
        ],
        _module_Text_CSV => [
            { name => '_csv_char',    text => "- *_char attributes", section => 'csv' },
            { name => '_options_csv', text => "-  Other attributes", section => 'csv' },
        ],
    };
    return $menu_insert->{$group};
}


sub config_insert {
    my ( $sf ) = @_;
    my $old_idx = 0;
    my $backup_old_idx = 0;
    my $group  = 'main_insert';

    GROUP_INSERT: while ( 1 ) {
        my $sub_menu_insert = $sf->__menu_insert( $group );

        OPTION_INSERT: while ( 1 ) {
            my $prompt;
            if ( $group =~ /^_module_(.+)\z/ ) {
                ( my $name = $1 ) =~ s/_/::/g;
                $prompt = '"' . $name . '"';
            }
            my @pre     = ( undef );
            my $choices = [ @pre, map( $_->{text}, @$sub_menu_insert ) ];
            # Choose
            $ENV{TC_RESET_AUTO_UP} = 0;
            my $idx = choose(
                $choices,
                { %{$sf->{i}{lyt_3}}, index => 1, default => $old_idx, undef => $sf->{i}{back_config}, prompt => $prompt }
            );
            if ( ! defined $idx || ! defined $choices->[$idx] ) {
                if ( $group =~ /^_module_/ ) {
                    $old_idx = $backup_old_idx;
                    $group = 'main_insert';
                    redo GROUP_INSERT;
                }
                else {
                    if ( $sf->{i}{write_config} ) {
                        $sf->__write_config_files();
                        delete $sf->{i}{write_config};
                    }
                    return
                }
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx = 0;
                    next OPTION_INSERT;
                }
                $old_idx = $idx;
            }
            else {
                if ( $old_idx != 0 ) {
                    $old_idx = 0;
                    next OPTION_INSERT;
                }
            }
            delete $ENV{TC_RESET_AUTO_UP};
            my $opt = $idx <= $#pre ? $pre[$idx] : $sub_menu_insert->[$idx - @pre]{name};
            if ( $opt =~ /^_module_/ ) {
                $backup_old_idx = $old_idx;
                $old_idx = 0;
                $group = $opt;
                redo GROUP_INSERT;
            }
            my $section  = $sub_menu_insert->[$idx - @pre]{section};
            #my $opt_type = 'o';
            my $no_yes   = [ 'NO', 'YES' ];
#            if ( $opt eq 'input_modes' ) {
#                    my $available = [ 'Cols', 'Rows', 'Multi-row', 'File' ];
#                    my $prompt = 'Input Modes:';
#                    $sf->__choose_a_subset_wrap( $section, $opt, $available, $prompt );
#            }
            if ( $opt eq 'files_dir' ) {
                $sf->__choose_a_dir_wrap( $section, $opt );
            }
            elsif ( $opt eq 'file_encoding' ) {
                my $items = [
                    { name => 'file_encoding', prompt => "file_encoding" },
                ];
                my $prompt = 'Encoding CSV files';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq 'max_files' ) {
                my $digits = 3;
                my $prompt = 'Max file history: ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits );
            }
            elsif ( $opt eq '_parse_mode' ) {
                my $prompt = 'Parsing mode';
                my $sub_menu = [
                    [ 'file_parse_mode', "From File   :", [ 'Text::CSV', 'split', 'Spreadsheet::Read' ] ],
                    [ 'copy_parse_mode', "Copy & Paste:", [ 'Text::CSV', 'split', 'Spreadsheet::Read' ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_csv_char' ) {
                my $items = [
                    { name => 'sep_char',    prompt => "sep_char   " },
                    { name => 'quote_char',  prompt => "quote_char " },
                    { name => 'escape_char', prompt => "escape_char" },
                    { name => 'eol',         prompt => "eol        " },
                ];
                my $prompt = '"Text::CSV"';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq '_options_csv' ) {
                my $prompt = '"Text::CSV"';
                my $sub_menu = [
                    [ 'allow_loose_escapes', "- allow_loose_escapes", [ 'NO', 'YES' ] ],
                    [ 'allow_loose_quotes',  "- allow_loose_quotes",  [ 'NO', 'YES' ] ],
                    [ 'allow_whitespace',    "- allow_whitespace",    [ 'NO', 'YES' ] ],
                    [ 'blank_is_undef',      "- blank_is_undef",      [ 'NO', 'YES' ] ],
                    [ 'binary',              "- binary",              [ 'NO', 'YES' ] ],
                    [ 'empty_is_undef',      "- empty_is_undef",      [ 'NO', 'YES' ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_parse_with_split' ) {
                my $items = [
                    { name => 'i_r_s', prompt => "IRS" },
                    { name => 'i_f_s', prompt => "IFS" },
                ];
                my $prompt = 'Separators (regexp)';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq 'create_table_defaults' ) {
                my $items = [
                    #{ name => 'id_col_name',       prompt => "Default ID col name" },
                    { name => 'default_data_type', prompt => "Default data type" },
                ];
                my $prompt = 'Create-table defaults';
                $sf->__group_readline( $section, $items, $prompt );
            }
            else { die "Unknown option: $opt" }
        }
    }
}


sub __menus {
    my ( $sf, $group ) = @_;
    my $menus = {
    # menu keys decide, where the options are located in the "db-browser" -h menu
        main => [
            { name => 'help',            text => "  HELP"   },
            { name => 'path',            text => "  Path"   },
            { name => 'config_database', text => "- DB"     },
            { name => 'config_menu',     text => "- Menu"   },
            { name => 'config_sql',      text => "- SQL",   },
            { name => 'config_output',   text => "- Output" },
            { name => 'config_insert',   text => "- Insert" },
        ],
        config_database => [
            { name => '_db_defaults', text => "- DB Settings"                },
            { name => 'plugins',      text => "- DB Plugins", section => 'G' },
        ],
        config_menu => [
            { name => '_menu_memory',  text => "- Menu Memory", section => 'G'     },
            { name => '_table_expand', text => "- Table",       section => 'table' },
            { name => 'mouse',         text => "- Mouse Mode",  section => 'table' },
        ],
        config_sql => [
            { name => 'max_rows',         text => "- Auto Limit",      section => 'G' },
            { name => 'meta',             text => "- Metadata",        section => 'G' },
            { name => 'operators',        text => "- Operators",       section => 'G' },
            { name => 'lock_stmt',        text => "- Lock Mode",       section => 'G' },
            { name => '_parentheses',     text => "- Parentheses",     section => 'G' },
            { name => '_sql_identifiers', text => "- Identifiers",     section => 'G' },

        ],
        config_output => [
            { name => 'min_col_width', text => "- Colwidth",      section => 'table' },
            { name => 'progress_bar',  text => "- ProgressBar",   section => 'table' },
            { name => 'tab_width',     text => "- Tabwidth",      section => 'table' },
            { name => 'grid',          text => "- Grid",          section => 'table' },
            { name => 'keep_header',   text => "- Keep Header",   section => 'table' },
            { name => 'undef',         text => "- Undef",         section => 'table' },
            { name => 'binary_filter', text => "- Binary filter", section => 'table' },
        ],
    };
    return $menus->{$group};
}


sub set_options {
    my ( $sf, $o ) = @_;
    $sf->{o} = $o || $sf->read_config_files();
    my $group = 'main';
    my $backup_old_idx = 0;
    my $old_idx = 0;

    GROUP: while ( 1 ) {
        my $menu = $sf->__menus( $group );

        OPTION: while ( 1 ) {
            my $back =          $group eq 'main' ? $sf->{i}{_quit}     : $sf->{i}{back_config};
            my @pre  = ( undef, $group eq 'main' ? $sf->{i}{_continue} : () );
            my $choices = [ @pre, map( $_->{text}, @$menu ) ];
            # Choose
            $ENV{TC_RESET_AUTO_UP} = 0;
            my $idx = choose(
                $choices,
                { %{$sf->{i}{lyt_3}}, index => 1, default => $old_idx, undef => $back }
            );
            if ( ! defined $idx || ! defined $choices->[$idx] ) {
                if ( $group =~ /^config_/ ) {
                    $old_idx = $backup_old_idx;
                    $group = 'main';
                    redo GROUP;
                }
                else {
                    if ( $sf->{i}{write_config} ) {
                        $sf->__write_config_files();
                        delete $sf->{i}{write_config};
                    }
                    exit();
                }
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx == $idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx = 0;
                    next OPTION;
                }
                $old_idx = $idx;
            }
            else {
                if ( $old_idx != 0 ) {
                    $old_idx = 0;
                    next OPTION;
                }
            }
            delete $ENV{TC_RESET_AUTO_UP};
            my $opt = $idx <= $#pre ? $pre[$idx] : $menu->[$idx - @pre]{name};
            if ( $opt eq 'config_insert' ) {
                $backup_old_idx = $old_idx;
                $sf->config_insert();
                $old_idx = $backup_old_idx;
                $group = 'main';
                redo GROUP;
            }
            elsif ( $opt =~ /^config_/ ) {
                $backup_old_idx = $old_idx;
                $old_idx = 0;
                $group = $opt;
                redo GROUP;
            }
            elsif ( $opt eq $sf->{i}{_continue} ) {
                if ( $sf->{i}{write_config} ) {
                    $sf->__write_config_files();
                    delete $sf->{i}{write_config};
                }
                return $sf->{o};
            }
            elsif ( $opt eq 'help' ) {
                require Pod::Usage;
                Pod::Usage::pod2usage( {
                    -exitval => 'NOEXIT',
                    -verbose => 2 } );
                next OPTION;
            }
            elsif ( $opt eq 'path' ) {
                my $version = 'version';
                my $bin     = '  bin  ';
                my $app_dir = 'app-dir';
                my $path = {
                    $version => $main::VERSION,
                    $bin     => catfile( $RealBin, $RealScript ),
                    $app_dir => $sf->{i}{app_dir},
                };
                my $opts = [ $version, $bin, $app_dir ];
                print_hash( $path, { keys => $opts, preface => ' Close with ENTER', clear_screen => 1 } );
                next OPTION;
            }
            elsif ( $opt eq '_db_defaults' ) {
                my $obj_o_db = App::DBBrowser::OptDB->new( $sf->{i}, $sf->{o} );
                $obj_o_db->database_setting();
                next OPTION;
            }
            #my $opt_type = 'o';
            my $section  = $menu->[$idx - @pre]{section};
            my $no_yes   = [ 'NO', 'YES' ];
            if ( $opt eq 'plugins' ) {
                my %installed_driver;
                for my $dir ( @INC ) {
                    my $glob_pattern = catfile $dir, 'App', 'DBBrowser', 'DB', '*.pm';
                    map { $installed_driver{( fileparse $_, '.pm' )[0]}++ } glob $glob_pattern;
                }
                my $prompt = 'Choose DB plugins:';
                $sf->__choose_a_subset_wrap( $section, $opt, [ sort keys %installed_driver ], $prompt );
            }
            elsif ( $opt eq 'tab_width' ) {
                my $digits = 3;
                my $prompt = 'Tab width: ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits );
            }
            elsif ( $opt eq 'grid' ) {
                my $prompt = '"Grid"';
                my $list = [ 'NO', 'YES' ];
                my $sub_menu = [ [ $opt, "  Grid", $list ] ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq 'keep_header' ) {
                my $prompt = '"Header each Page"';
                my $list = [ 'NO', 'YES' ];
                my $sub_menu = [ [ $opt, "  Keep Header", $list ] ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq 'binary_filter' ) {
                my $prompt = 'Print "BNRY" instead of binary data';
                my $list = [ 'NO', 'YES' ];
                my $sub_menu = [ [ $opt, "  Binary filter", $list ] ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq 'min_col_width' ) {
                my $digits = 3;
                my $prompt = 'Min column width: ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits );
            }
            elsif ( $opt eq 'undef' ) {
                my $items = [
                    { name => 'undef', prompt => "undef" },
                ];
                my $prompt = 'Print replacement for undefined table values.';
                $sf->__group_readline( $section, $items, $prompt );
            }
            elsif ( $opt eq 'progress_bar' ) {
                my $digits = 7;
                my $prompt = 'Threshold ProgressBar: ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits );
            }
            elsif ( $opt eq 'max_rows' ) {
                my $digits = 7;
                my $prompt = 'Max rows: ';
                $sf->__choose_a_number_wrap( $section, $opt, $prompt, $digits );
            }
            elsif ( $opt eq 'lock_stmt' ) {
                my $prompt = 'SQL statement: ';
                my $list = [ 'Lk0', 'Lk1' ];
                my $sub_menu = [ [ $opt, "  Lock Mode", $list ] ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq 'meta' ) {
                my $prompt = 'DB/schemas/tables: ';
                my $list = $no_yes;
                my $sub_menu = [ [ $opt, "  Add metadata", $list ] ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_parentheses' ) {
                my $sub_menu = [
                    [ 'parentheses_w', "- Parens in WHERE",     [ 'NO', 'YES' ] ],
                    [ 'parentheses_h', "- Parens in HAVING TO", [ 'NO', 'YES' ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu );
            }
            elsif ( $opt eq 'operators' ) {
                my $available =[
                    "REGEXP", "REGEXP_i", "NOT REGEXP", "NOT REGEXP_i", "LIKE", "NOT LIKE", "IS NULL", "IS NOT NULL",
                    "IN", "NOT IN", "BETWEEN", "NOT BETWEEN", " = ", " != ", " <> ", " < ", " > ", " >= ", " <= ",
                    " = col", " != col", " <> col", " < col", " > col", " >= col", " <= col",
                    "LIKE %col%", "NOT LIKE %col%",  "LIKE col%", "NOT LIKE col%", "LIKE %col", "NOT LIKE %col" ],
                    # "LIKE col", "NOT LIKE col"
                my $prompt = 'Choose operators:';
                $sf->__choose_a_subset_wrap( $section, $opt, $available, $prompt );
            }
            elsif ( $opt eq '_sql_identifiers' ) {
                my $prompt = 'Choose: ';
                my $sub_menu = [
                    [ 'qualified_table_name', "- Qualified table names", [ 'NO', 'YES' ] ],
                    [ 'quote_identifiers',    "- Quote identifiers",     [ 'NO', 'YES' ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq 'mouse' ) {
                my $prompt = 'Choose: ';
                my $list = [ 0, 1, 2, 3, 4 ];
                my $sub_menu = [ [ $opt, "  Mouse mode", $list ] ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_menu_memory' ) {
                my $prompt = 'Choose: ';
                my $sub_menu = [
                    [ 'menu_memory',     "- Menu memory", [ 'NO', 'YES' ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            elsif ( $opt eq '_table_expand' ) {
                my $prompt = 'Choose: ';
                my $sub_menu = [
                    [ 'table_expand', "- Expand Rows",   [ 'NO', 'YES - fast back', 'YES' ] ],
                ];
                $sf->__settings_menu_wrap( $section, $sub_menu, $prompt );
            }
            else { die "Unknown option: $opt" }
        }
    }
}


sub __settings_menu_wrap {
    my ( $sf, $section, $sub_menu, $prompt ) = @_;
    my $changed = settings_menu( $sub_menu, $sf->{o}{$section}, { prompt => $prompt, mouse => $sf->{o}{table}{mouse} } );
    return if ! $changed;
    $sf->{i}{write_config}++;
}

sub __choose_a_subset_wrap {
    my ( $sf, $section, $opt, $available, $prompt ) = @_;
    my $current = $sf->{o}{$section}{$opt};
    # Choose_list
    my $info = 'curr> ' . join( ', ', @$current );
    my $name = ' new> ';
    my $list = choose_a_subset(
        $available,
        { info => $info, name => $name, prompt => $prompt, prefix => '- ', index => 0,
          clear_screen => 1, mouse => $sf->{o}{table}{mouse} }
    );
    return if ! defined $list;
    return if ! @$list;
    $sf->{o}{$section}{$opt} = $list;
    $sf->{i}{write_config}++;
    return;
}

sub __choose_a_number_wrap {
    my ( $sf, $section, $opt, $prompt, $digits ) = @_;
    my $current = $sf->{o}{$section}{$opt};
    my $w = $digits + int( ( $digits - 1 ) / 3 ) * length $sf->{o}{G}{thsd_sep};
    my $info = 'Curr> ' . $prompt . sprintf( "%*s", $w, insert_sep( $current, $sf->{o}{G}{thsd_sep} ) );
    my $name = ' New> ' . $prompt;
    # Choose_a_number
    my $choice = choose_a_number(
        $digits, { name => $name, info => $info, mouse => $sf->{o}{table}{mouse}, clear_screen => 1 }
    );
    return if ! defined $choice;
    $sf->{o}{$section}{$opt} = $choice;
    $sf->{i}{write_config}++;
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
    my $trs = Term::Form->new();
    my $new_list = $trs->fill_form(
        $list,
        { prompt => $prompt, auto_up => 2, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back} }
    );
    if ( $new_list ) {
        for my $i ( 0 .. $#$items ) {
            $sf->{o}{$section}{$items->[$i]{name}} = $new_list->[$i][1];
        }
        $sf->{i}{write_config}++;
    }
}

sub __choose_a_dir_wrap {
    my ( $sf, $section, $opt ) = @_;
    my $current = $sf->{o}{$section}{$opt};
    # Choose_a_dir
    my $dir = choose_a_dir( { mouse => $sf->{o}{table}{mouse}, current => $current } );
    return if ! length $dir;
    $sf->{o}{$section}{$opt} = $dir;
    $sf->{i}{write_config}++;
    return;
}


sub __write_config_files {
    my ( $sf ) = @_;
    my $tmp = {};
    for my $section ( keys %{$sf->{o}} ) {
        for my $opt ( keys %{$sf->{o}{$section}} ) {
            $tmp->{$section}{$opt} = $sf->{o}{$section}{$opt};
        }
    }
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $file_name = $sf->{i}{file_settings};
    $ax->write_json( $file_name, $tmp  );
}

sub read_config_files {
    my ( $sf ) = @_;
    my $o = $sf->defaults();
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $file_name = $sf->{i}{file_settings};
    if ( -f $file_name && -s $file_name ) {
        my $tmp = $ax->read_json( $file_name );
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
