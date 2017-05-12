package # hide from PAUSE
App::DBBrowser::Opt;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '1.053';

use File::Basename        qw( basename fileparse );
use File::Spec::Functions qw( catfile );
use FindBin               qw( $RealBin $RealScript );
#use Pod::Usage            qw( pod2usage );  # "require"-d

use Term::Choose       qw( choose );
use Term::Choose::Util qw( insert_sep print_hash choose_a_number choose_a_subset settings_menu choose_dirs choose_a_dir );
use Term::Form         qw();

use App::DBBrowser::DB;
use App::DBBrowser::Auxil;



sub new {
    my ( $class, $info, $opt, $db_opt ) = @_;
    bless { info => $info, opt => $opt, db_opt => $db_opt }, $class;
}


sub defaults {
    my ( $self, $section, $key ) = @_;
    my $defaults = {
        G => {
            db_plugins           => [ 'SQLite', 'mysql', 'Pg' ],
            menus_config_memory  => 0,
            menu_sql_memory      => 0,
            menus_db_memory      => 0,
            thsd_sep             => ',',
            metadata             => 0,
            lock_stmt            => 0,
            operators            => [ "REGEXP", "REGEXP_i", " = ", " != ", " < ", " > ", "IS NULL", "IS NOT NULL" ],
            parentheses_w        => 0,
            parentheses_h        => 0,
        },
        table => {
            table_expand         => 1,
            mouse                => 0,
            max_rows             => 50_000,
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
            input_modes          => [ 'Cols', 'Rows', 'Multi-row', 'File' ],
            files_dir            => undef,
            file_encoding        => 'UTF-8',
            max_files            => 15,
        # Parsing
            parse_mode           => 0,
            # Text::CSV:
            sep_char             => ',',
            quote_char           => '"',
            escape_char          => '"',
            allow_loose_escapes  => 0,
            allow_loose_quotes   => 0,
            allow_whitespace     => 0,
            auto_diag            => 1,
            blank_is_undef       => 1,
            binary               => 1,
            empty_is_undef       => 0,
            # split:
            i_r_s                => '\n',
            i_f_s                => ',',
        # create table defaults:
            id_col_name          => 'ID_a',
            default_data_type    => 'TEXT',
        }
    };
    return $defaults                   if ! $section;
    return $defaults->{$section}       if ! $key;
    return $defaults->{$section}{$key};
}


sub __sub_menus_insert {
    my ( $self, $group ) = @_;
    my $sub_menus_insert = {
        main_insert => [
            { name => 'input_modes',           text => "- Read",          section => 'insert' },
            { name => 'files_dir',             text => "- File Dir",      section => 'insert' },
            { name => 'file_encoding',         text => "- File Encoding", section => 'insert' },
            { name => 'max_files',             text => "- File History",  section => 'insert' },
            { name => 'parse_mode',            text => "- Parse-mode",    section => 'insert' },
            { name => '_module_Text_CSV',      text => "- conf T::CSV",   section => 'insert' },
            { name => '_parse_with_split',     text => "- conf 'split'",  section => 'insert' },
            { name => 'create_table_defaults', text => "- Create-table",  section => 'insert' },
        ],
        _module_Text_CSV => [
            { name => '_csv_char',    text => "- *_char attributes", section => 'insert' },
            { name => '_options_csv', text => "-  Other attributes", section => 'insert' },
        ],
    };
    return $sub_menus_insert->{$group};
}


sub __config_insert {
    my ( $self ) = @_;
    my $old_idx = 0;
    my $backup_old_idx = 0;
    my $group  = 'main_insert';

    GROUP_INSERT: while ( 1 ) {
        my $sub_menu_insert = $self->__sub_menus_insert( $group );

        OPTION_INSERT: while ( 1 ) {
            my $prompt;
            if ( $group =~ /^_module_(.+)\z/ ) {
                ( my $name = $1 ) =~ s/_/::/g;
                $prompt = '"' . $name . '"';
            }
            my @pre     = ( undef );
            my $choices = [ @pre, map( $_->{text}, @$sub_menu_insert ) ];
            # Choose
            my $idx = choose(
                $choices,
                { %{$self->{info}{lyt_3}}, index => 1, default => $old_idx, undef => $self->{info}{back_short}, prompt => $prompt }
            );
            if ( ! defined $idx || ! defined $choices->[$idx] ) {
                if ( $group =~ /^_module_/ ) {
                    $old_idx = $backup_old_idx;
                    $group = 'main_insert';
                    redo GROUP_INSERT;
                }
                else {
                    if ( $self->{info}{write_config} ) {
                        $self->__write_config_files();
                        delete $self->{info}{write_config};
                    }
                    return
                }
            }
            if ( $self->{opt}{G}{menus_config_memory} ) {
                if ( $old_idx == $idx ) {
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
            my $option = $idx <= $#pre ? $pre[$idx] : $sub_menu_insert->[$idx - @pre]{name};
            if ( $option =~ /^_module_/ ) {
                $backup_old_idx = $old_idx;
                $old_idx = 0;
                $group = $option;
                redo GROUP_INSERT;
            }
            my $section  = $sub_menu_insert->[$idx - @pre]{section};
            my $opt_type = 'opt';
            my $no_yes   = [ 'NO', 'YES' ];
            if ( $option eq 'input_modes' ) {
                    my $available = [ 'Cols', 'Rows', 'Multi-row', 'File' ];
                    my $prompt = 'Input Modes:';
                    $self->__opt_choose_a_list( $opt_type, $section, $option, $available, $prompt );
            }
            elsif ( $option eq 'files_dir' ) {
                $self->__opt_choose_a_dir( $opt_type, $section, $option );
            }
            elsif ( $option eq 'file_encoding' ) {
                my $items = [
                    { name => 'file_encoding', prompt => "file_encoding" },
                ];
                my $prompt = 'Encoding CSV files';
                $self->__group_readline( $opt_type, $section, $items, $prompt );
            }
            elsif ( $option eq 'max_files' ) {
                my $digits = 3;
                my $prompt = '"Max file history"';
                $self->__opt_number_range( $opt_type, $section, $option, $prompt, $digits );
            }
            elsif ( $option eq 'parse_mode' ) {
                my $prompt = 'Parsing CSV files';
                my $list = [ 'Text::CSV', 'split', 'Spreadsheet::Read' ];
                my $sub_menu = [ [ $option, "  Use", $list ] ];
                $self->__opt_settings_menu( $opt_type, $section, $sub_menu, $prompt );
            }
            elsif ( $option eq '_csv_char' ) {
                my $items = [
                    { name => 'sep_char',    prompt => "sep_char   " },
                    { name => 'quote_char',  prompt => "quote_char " },
                    { name => 'escape_char', prompt => "escape_char" },
                ];
                my $prompt = '"Text::CSV"';
                $self->__group_readline( $opt_type, $section, $items, $prompt );
            }
            elsif ( $option eq '_options_csv' ) {
                my $prompt = '"Text::CSV"';
                my $sub_menu = [
                    [ 'allow_loose_escapes', "- allow_loose_escapes", [ 'NO', 'YES' ] ],
                    [ 'allow_loose_quotes',  "- allow_loose_quotes",  [ 'NO', 'YES' ] ],
                    [ 'allow_whitespace',    "- allow_whitespace",    [ 'NO', 'YES' ] ],
                    [ 'blank_is_undef',      "- blank_is_undef",      [ 'NO', 'YES' ] ],
                    [ 'empty_is_undef',      "- empty_is_undef",      [ 'NO', 'YES' ] ],
                ];
                $self->__opt_settings_menu( $opt_type, $section, $sub_menu, $prompt );
            }
            elsif ( $option eq '_parse_with_split' ) {
                my $items = [
                    { name => 'i_r_s', prompt => "IRS" },
                    { name => 'i_f_s', prompt => "IFS" },
                ];
                my $prompt = 'Separators (regexp)';
                $self->__group_readline( $opt_type, $section, $items, $prompt );
            }
            elsif ( $option eq 'create_table_defaults' ) {
                my $items = [
                    { name => 'id_col_name',       prompt => "Default ID col name" },
                    { name => 'default_data_type', prompt => "Default data type  " },
                ];
                my $prompt = 'Create-table defaults';
                $self->__group_readline( $opt_type, $section, $items, $prompt );
            }
            else { die "Unknown option: $option" }
        }
    }
}


sub __menus {
    my ( $self, $group ) = @_;
    my $menus = {
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
            { name => 'db_plugins',   text => "- DB Plugins", section => 'G' },
        ],
        config_menu => [
            { name => '_menu_memory',  text => "- Menu Memory", section => 'G' },
            { name => '_table_expand', text => "- Table",       section => 'table' },
            { name => 'mouse',         text => "- Mouse Mode",  section => 'table' },
        ],
        config_sql => [
            { name => 'metadata',     text => "- Metadata",    section => 'G' },
            { name => 'operators',    text => "- Operators",   section => 'G' },
            { name => 'lock_stmt',    text => "- Lock Mode",   section => 'G' },
            { name => '_parentheses', text => "- Parentheses", section => 'G' },

        ],
        config_output => [
            { name => 'max_rows',      text => "- Max Rows",    section => 'table' },
            { name => 'min_col_width', text => "- Colwidth",    section => 'table' },
            { name => 'progress_bar',  text => "- ProgressBar", section => 'table' },
            { name => 'tab_width',     text => "- Tabwidth",    section => 'table' },
            { name => 'grid',          text => "- Grid",        section => 'table' },
            { name => 'keep_header',   text => "- Keep Header", section => 'table' },
            { name => 'undef',         text => "- Undef",       section => 'table' },
        ],
    };
    return $menus->{$group};
}


sub __set_options {
    my ( $self ) = @_;
    my $group = 'main';
    my $backup_old_idx = 0;
    my $old_idx = 0;

    GROUP: while ( 1 ) {
        my $menu = $self->__menus( $group );

        OPTION: while ( 1 ) {
            my $back =          $group eq 'main' ? $self->{info}{_quit}     : $self->{info}{back_short};
            my @pre  = ( undef, $group eq 'main' ? $self->{info}{_continue} : () );
            my $choices = [ @pre, map( $_->{text}, @$menu ) ];
            # Choose
            my $idx = choose(
                $choices,
                { %{$self->{info}{lyt_3}}, index => 1, default => $old_idx, undef => $back }
            );
            if ( ! defined $idx || ! defined $choices->[$idx] ) {
                if ( $group =~ /^config_/ ) {
                    $old_idx = $backup_old_idx;
                    $group = 'main';
                    redo GROUP;
                }
                else {
                    if ( $self->{info}{write_config} ) {
                        $self->__write_config_files();
                        delete $self->{info}{write_config};
                    }
                    exit();
                }
            }
            if ( $self->{opt}{G}{menus_config_memory} ) {
                if ( $old_idx == $idx ) {
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
            my $option = $idx <= $#pre ? $pre[$idx] : $menu->[$idx - @pre]{name};
            if ( $option eq 'config_insert' ) {
                $backup_old_idx = $old_idx;
                $self->__config_insert();
                $old_idx = $backup_old_idx;
                $group = 'main';
                redo GROUP;
            }
            elsif ( $option =~ /^config_/ ) {
                $backup_old_idx = $old_idx;
                $old_idx = 0;
                $group = $option;
                redo GROUP;
            }
            elsif ( $option eq $self->{info}{_continue} ) {
                if ( $self->{info}{write_config} ) {
                    $self->__write_config_files();
                    delete $self->{info}{write_config};
                }
                return $self->{opt}, $self->{db_opt};
            }
            elsif ( $option eq 'help' ) {
                require Pod::Usage;
                Pod::Usage::pod2usage( {
                    -exitval => 'NOEXIT',
                    -verbose => 2 } );
                next OPTION;
            }
            elsif ( $option eq 'path' ) {
                my $version = 'version';
                my $bin     = '  bin  ';
                my $app_dir = 'app-dir';
                my $path = {
                    $version => $main::VERSION,
                    $bin     => catfile( $RealBin, $RealScript ),
                    $app_dir => $self->{info}{app_dir},
                };
                my $names = [ $version, $bin, $app_dir ];
                print_hash( $path, { keys => $names, preface => ' Close with ENTER' } );
                next OPTION;
            }
            elsif ( $option eq '_db_defaults' ) {
                $self->__database_setting();
                next OPTION;
            }
            my $opt_type = 'opt';
            my $section  = $menu->[$idx - @pre]{section};
            my $no_yes   = [ 'NO', 'YES' ];
            if ( $option eq 'db_plugins' ) {
                my %installed_db_driver;
                for my $dir ( @INC ) {
                    my $glob_pattern = catfile $dir, 'App', 'DBBrowser', 'DB', '*.pm';
                    map { $installed_db_driver{( fileparse $_, '.pm' )[0]}++ } glob $glob_pattern;
                }
                my $prompt = 'Choose DB plugins:';
                $self->__opt_choose_a_list( $opt_type, $section, $option, [ sort keys %installed_db_driver ], $prompt );
                $self->__read_db_config_files();
            }
            elsif ( $option eq 'tab_width' ) {
                my $digits = 3;
                my $prompt = '"Tab width"';
                $self->__opt_number_range( $opt_type, $section, $option, $prompt, $digits );
            }
            elsif ( $option eq 'grid' ) {
                my $prompt = '"Grid"';
                my $list = [ 'NO', 'YES' ];
                my $sub_menu = [ [ $option, "  Grid", $list ] ];
                $self->__opt_settings_menu( $opt_type, $section, $sub_menu, $prompt );
            }
            elsif ( $option eq 'keep_header' ) {
                my $prompt = '"Header each Page"';
                my $list = [ 'NO', 'YES' ];
                my $sub_menu = [ [ $option, "  Keep Header", $list ] ];
                $self->__opt_settings_menu( $opt_type, $section, $sub_menu, $prompt );
            }
            elsif ( $option eq 'min_col_width' ) {
                my $digits = 3;
                my $prompt = '"Min column width"';
                $self->__opt_number_range( $opt_type, $section, $option, $prompt, $digits );
            }
            elsif ( $option eq 'undef' ) {
                my $items = [
                    { name => 'undef', prompt => "undef" },
                ];
                my $prompt = 'Print replacement for undefined table values.';
                $self->__group_readline( $opt_type, $section, $items, $prompt );
            }
            elsif ( $option eq 'progress_bar' ) {
                my $digits = 7;
                my $prompt = '"Threshold ProgressBar"';
                $self->__opt_number_range( $opt_type, $section, $option, $prompt, $digits );
            }
            elsif ( $option eq 'max_rows' ) {
                my $digits = 7;
                my $prompt = '"Max rows"';
                $self->__opt_number_range( $opt_type, $section, $option, $prompt, $digits );
            }
            elsif ( $option eq 'lock_stmt' ) {
                my $prompt = 'SQL statement: ';
                my $list = [ 'Lk0', 'Lk1' ];
                my $sub_menu = [ [ $option, "  Lock Mode", $list ] ];
                $self->__opt_settings_menu( $opt_type, $section, $sub_menu, $prompt );
            }
            elsif ( $option eq 'metadata' ) {
                my $prompt = 'DB/schemas/tables: ';
                my $list = $no_yes;
                my $sub_menu = [ [ $option, "  Add metadata", $list ] ];
                $self->__opt_settings_menu( $opt_type, $section, $sub_menu, $prompt );
            }
            elsif ( $option eq '_parentheses' ) {
                my $sub_menu = [
                    [ 'parentheses_w', "- Parens in WHERE",     [ 'NO', 'YES' ] ],
                    [ 'parentheses_h', "- Parens in HAVING TO", [ 'NO', 'YES' ] ],
                ];
                $self->__opt_settings_menu( $opt_type, $section, $sub_menu );
            }
            elsif ( $option eq 'operators' ) {
                my $available = $self->{info}{avail_operators};
                my $prompt = 'Choose operators:';
                $self->__opt_choose_a_list( $opt_type, $section, $option, $available, $prompt );
            }
            elsif ( $option eq 'mouse' ) {
                my $prompt = 'Choose: ';
                my $list = [ 0, 1, 2, 3, 4 ];
                my $sub_menu = [ [ $option, "  Mouse mode", $list ] ];
                $self->__opt_settings_menu( $opt_type, $section, $sub_menu, $prompt );
            }
            elsif ( $option eq '_menu_memory' ) {
                my $prompt = 'Choose: ';
                my $sub_menu = [
                    [ 'menus_config_memory', "- Config Menus", [ 'Simple', 'Memory' ] ],
                    [ 'menu_sql_memory',     "- SQL    Menu",  [ 'Simple', 'Memory' ] ],
                    [ 'menus_db_memory',     "- DB     Menus", [ 'Simple', 'Memory' ] ],
                ];
                $self->__opt_settings_menu( $opt_type, $section, $sub_menu, $prompt );
            }
            elsif ( $option eq '_table_expand' ) {
                my $prompt = 'Choose: ';
                my $sub_menu = [
                    [ 'table_expand', "- Expand Rows",   [ 'NO', 'YES - fast back', 'YES' ] ],
                ];
                $self->__opt_settings_menu( $opt_type, $section, $sub_menu, $prompt );
            }
            else { die "Unknown option: $option" }
        }
    }
}


sub __opt_settings_menu {
    my ( $self, $opt_type, $section, $sub_menu, $prompt ) = @_;
    my $changed = settings_menu( $sub_menu, $self->{$opt_type}{$section}, { prompt => $prompt } );
    return if ! $changed;
    $self->{info}{write_config}++;
}


sub __opt_choose_a_list {
    my ( $self, $opt_type, $section, $option, $available, $prompt ) = @_;
    my $current = $self->{$opt_type}{$section}{$option};
    # Choose_list
    my $list = choose_a_subset( $available, { prompt => $prompt, current => $current, index => 0 } );
    return if ! defined $list;
    return if ! @$list;
    $self->{$opt_type}{$section}{$option} = $list;
    $self->{info}{write_config}++;
    return;
}


sub __opt_number_range {
    my ( $self, $opt_type, $section, $option, $prompt, $digits ) = @_;
    my $current = $self->{$opt_type}{$section}{$option};
    $current = insert_sep( $current, $self->{opt}{G}{thsd_sep} );
    # Choose_a_number
    my $choice = choose_a_number( $digits, { name => $prompt, current => $current } );
    return if ! defined $choice;
    $self->{$opt_type}{$section}{$option} = $choice eq '--' ? undef : $choice;
    $self->{info}{write_config}++;
    return;
}


sub __group_readline {
    my ( $self, $opt_type, $section, $items, $prompt ) = @_;
    my $list = [ map {
        [
            exists $_->{prompt} ? $_->{prompt} : $_->{name},
            $self->{$opt_type}{$section}{$_->{name}}
        ]
    } @{$items} ];
    my $trs = Term::Form->new();
    my $new_list = $trs->fill_form(
        $list,
        { prompt => $prompt, auto_up => 2, confirm => $self->{info}{_confirm}, back => $self->{info}{_back} }
    );
    if ( $new_list ) {
        for my $i ( 0 .. $#$items ) {
            $self->{$opt_type}{$section}{$items->[$i]{name}} = $new_list->[$i][1];
        }
        $self->{info}{write_config}++;
    }
}


sub __opt_choose_a_dir {
    my ( $self, $opt_type, $section, $option ) = @_;
    my $current = $self->{$opt_type}{$section}{$option};
    # Choose_a_dir
    my $dir = choose_a_dir( { mouse => $self->{opt}{table}{mouse}, current => $current } );
    return if ! length $dir;
    $self->{$opt_type}{$section}{$option} = $dir;
    $self->{info}{write_config}++;
    return;
}


sub __opt_choose_dirs {
    my ( $self, $opt_type, $section, $option ) = @_;
    my $current = $self->{$opt_type}{$section}{$option};
    # Choose_dirs
    my $dirs = choose_dirs( { mouse => $self->{opt}{table}{mouse}, current => $current } );
    return if ! defined $dirs;
    return if ! @$dirs;
    $self->{$opt_type}{$section}{$option} = $dirs;
    $self->{info}{write_config}++;
    return;
}


sub __database_setting {
    my ( $self, $db ) = @_;
    my $changed = 0;
    SECTION: while ( 1 ) {
        my ( $db_driver, $db_plugin, $section );
        if ( defined $db ) {
            $db_plugin = $self->{info}{db_plugin};
            $db_driver = $self->{info}{db_driver};
            $section   = $db_plugin . '_' . $db;
            for my $option ( keys %{$self->{opt}{$db_plugin}} ) {
                next if $option eq 'directories_sqlite';
                if ( ! defined $self->{opt}{$section}{$option} ) {
                    $self->{opt}{$section}{$option} = $self->{opt}{$db_plugin}{$option};
                }
            }
        }
        else {
            if ( @{$self->{opt}{G}{db_plugins}} == 1 ) {
                $db_plugin = $self->{opt}{G}{db_plugins}[0];
            }
            else {
                # Choose
                $db_plugin = choose(
                    [ undef, map( "- $_", @{$self->{opt}{G}{db_plugins}} ) ],
                    { %{$self->{info}{lyt_3}}, undef => $self->{info}{back_short} }
                );
                return if ! defined $db_plugin;
            }
            $db_plugin =~ s/^-\ //;
            $self->{info}{db_plugin} = $db_plugin;
            $section = $db_plugin;
        }
        my $obj_db = App::DBBrowser::DB->new( $self->{info}, $self->{opt} );
        $db_driver = $obj_db->db_driver() if ! $db_driver;
        my $env_variables = $obj_db->environment_variables();
        my $login_data    = $obj_db->read_arguments();
        my $connect_attr  = $obj_db->choose_arguments();
        my $items = {
            required => [ map { {
                    name         => 'field_' . $_->{name},
                    prompt       => exists $_->{prompt} ? $_->{prompt} : $_->{name},
                    avail_values => [ 'NO', 'YES' ]
                } } @$login_data ],
            env_variables => [ map { {
                    name         => $_,
                    prompt       => $_,
                    avail_values => [ 'NO', 'YES' ]
                } } @$env_variables ],
            read_argument   => [
                    grep { ! $_->{keep_secret} } @$login_data
                ],
            choose_argument => $connect_attr,
        };
        push @{$items->{choose_argument}}, {
            name          => 'binary_filter',
            avail_values  => [ 0, 1 ],
            default_index => 0,
        };
        my @groups;
        push @groups, [ 'required',        "- Fields"             ] if @{$items->{required}};
        push @groups, [ 'env_variables',   "- ENV Variables"      ] if @{$items->{env_variables}};
        push @groups, [ 'read_argument',   "- Login Data"         ] if @{$items->{read_argument}};
        push @groups, [ 'choose_argument', "- DB Options"         ];
        push @groups, [ 'sqlite_dir',      "- Sqlite directories" ] if $db_driver eq 'SQLite';
        my $prompt = defined $db ? 'DB: "' . ( $db_driver eq 'SQLite' ? basename $db : $db )
                                 : 'Plugin "' . $db_plugin . '"';
        my $opt_type = 'db_opt';
        my $old_idx_group = 0;

        GROUP: while ( 1 ) {
            my $reset = '  Reset DB';
            my @pre = ( undef );
            my $choices = [ @pre, map( $_->[1], @groups ) ];
            push @$choices, $reset if ! defined $db;
            # Choose
            my $idx_group = choose(
                $choices,
                { %{$self->{info}{lyt_3}}, prompt => $prompt, index => 1,
                  default => $old_idx_group, undef => $self->{info}{back_short} }
            );
            if ( ! defined $idx_group || ! defined $choices->[$idx_group] ) {
                if ( $self->{info}{write_config} ) {
                    $self->__write_db_config_files();
                    delete $self->{info}{write_config};
                    $changed++;
                }
                next SECTION if ! $db && @{$self->{opt}{G}{db_plugins}} > 1;
                return $changed;
            }
            if ( $self->{opt}{G}{menus_config_memory} ) {
                if ( $old_idx_group == $idx_group ) {
                    $old_idx_group = 0;
                    next GROUP;
                }
                else {
                    $old_idx_group = $idx_group;
                }
            }
            if ( $choices->[$idx_group] eq $reset ) {
                my @databases;
                for my $section ( keys %{$self->{db_opt}} ) {
                    push @databases, $1 if $section =~ /^\Q$db_plugin\E_(.+)\z/;
                }
                if ( ! @databases ) {
                    choose(
                        [ 'No databases with customized settings.' ],
                        { %{$self->{info}{lyt_stop}}, prompt => 'Press ENTER' }
                    );
                    next GROUP;
                }
                my $choices = choose_a_subset(
                    [ sort @databases ],
                    { p_new => 'Reset DB: ' }
                );
                if ( ! $choices->[0] ) {
                    next GROUP;
                }
                for my $db ( @$choices ) {
                    my $section = $db_plugin . '_' . $db;
                    delete $self->{db_opt}{$section};
                }
                $self->{info}{write_config}++;
                next GROUP;;
            }
            my $group  = $groups[$idx_group-@pre][0];
            if ( $group eq 'required' ) {
                my $sub_menu = [];
                for my $item ( @{$items->{$group}} ) {
                    my $required = $item->{name};
                    push @$sub_menu, [ $required, '- ' . $item->{prompt}, $item->{avail_values} ];
                    if ( ! defined $self->{db_opt}{$section}{$required} ) {
                        if ( defined $self->{db_opt}{$db_plugin}{$required} ) {
                            $self->{db_opt}{$section}{$required} = $self->{db_opt}{$db_plugin}{$required};
                        }
                        else {
                            $self->{db_opt}{$section}{$required} = 1;  # All fields required by default
                        }
                    }
                }
                my $prompt = 'Required fields (' . $db_plugin . '):';
                $self->__opt_settings_menu( $opt_type, $section, $sub_menu, $prompt );
                next GROUP;
            }
            elsif ( $group eq 'env_variables' ) {
                my $sub_menu = [];
                for my $item ( @{$items->{$group}} ) {
                    my $env_variable = $item->{name};
                    push @$sub_menu, [ $env_variable, '- ' . $item->{prompt}, $item->{avail_values} ];
                    if ( ! defined $self->{db_opt}{$section}{$env_variable} ) {
                        if ( defined $self->{db_opt}{$db_plugin}{$env_variable} ) {
                            $self->{db_opt}{$section}{$env_variable} = $self->{db_opt}{$db_plugin}{$env_variable};
                        }
                        else {
                            $self->{db_opt}{$section}{$env_variable} = 0;
                        }
                    }
                }
                my $prompt = 'Use ENV variables (' . $db_plugin . '):';
                $self->__opt_settings_menu( $opt_type, $section, $sub_menu, $prompt );
                next GROUP;
            }
            elsif ( $group eq 'read_argument' ) {
               for my $item ( @{$items->{$group}} ) {
                    my $option = $item->{name};
                    if ( ! defined $self->{db_opt}{$section}{$option} ) {
                        if ( defined $self->{db_opt}{$db_plugin}{$option} ) {
                            $self->{db_opt}{$section}{$option} = $self->{db_opt}{$db_plugin}{$option};
                        }
                    }
                }
                my $prompt = 'Default login data (' . $db_plugin . '):';
                $self->__group_readline( $opt_type, $section, $items->{$group}, $prompt );
            }
            elsif ( $group eq 'choose_argument' ) {
                my $sub_menu = [];
                for my $item ( @{$items->{$group}} ) {
                    my $option = $item->{name};
                    my $prompt = '- ' . ( exists $item->{prompt} ? $item->{prompt} : $item->{name} );
                    push @$sub_menu, [ $option, $prompt, $item->{avail_values} ];
                    if ( ! defined $self->{db_opt}{$section}{$option} ) {
                        if ( defined $self->{db_opt}{$db_plugin}{$option} ) {
                            $self->{db_opt}{$section}{$option} = $self->{db_opt}{$db_plugin}{$option};
                        }
                        else {
                            $self->{db_opt}{$section}{$option} = $item->{avail_values}[$item->{default_index}];
                        }
                    }
                }
                my $prompt = 'Options (' . $db_plugin . '):';
                $self->__opt_settings_menu( $opt_type, $section, $sub_menu, $prompt );
                next GROUP;
            }
            elsif ( $group eq 'sqlite_dir' ) {
                my $option = 'directories_sqlite';
                $self->__opt_choose_dirs( $opt_type, $section, $option );
                next GROUP;
            }
        }
    }
}


sub __write_config_files {
    my ( $self ) = @_;
    my $fmt = $self->{info}{conf_file_fmt};
    my $tmp = {};
    for my $section ( keys %{$self->{opt}} ) {
        for my $option ( keys %{$self->{opt}{$section}} ) {
            $tmp->{$section}{$option} = $self->{opt}{$section}{$option};
        }
    }
    my $auxil = App::DBBrowser::Auxil->new( $self->{info} );
    my $file_name = $self->{info}{config_generic};
    $auxil->__write_json( sprintf( $fmt, $file_name ), $tmp  );
}


sub __write_db_config_files {
    my ( $self ) = @_;
    my $regexp_db_plugins = join '|', map quotemeta, @{$self->{opt}{G}{db_plugins}};
    my $fmt = $self->{info}{conf_file_fmt};
    my $tmp = {};
    for my $section ( sort keys %{$self->{db_opt}} ) {
        if ( $section =~ /^($regexp_db_plugins)(?:_(.+))?\z/ ) {
            my ( $db_plugin, $conf_sect ) = ( $1, $2 );
            $conf_sect = '*' . $db_plugin if ! defined $conf_sect;
            for my $option ( keys %{$self->{db_opt}{$section}} ) {
                $tmp->{$db_plugin}{$conf_sect}{$option} = $self->{db_opt}{$section}{$option};
            }
        }
    }
    my $auxil = App::DBBrowser::Auxil->new( $self->{info} );
    for my $section ( keys %$tmp ) {
        my $file_name =  $section;
        $auxil->__write_json( sprintf( $fmt, $file_name ), $tmp->{$section}  );
    }
}


sub __read_config_files {
    my ( $self ) = @_;
    $self->{opt} = $self->defaults();
    my $fmt = $self->{info}{conf_file_fmt};
    my $auxil = App::DBBrowser::Auxil->new( $self->{info} );
    my $file =  sprintf( $fmt, $self->{info}{config_generic} );
    if ( -f $file && -s $file ) {
        my $tmp = $auxil->__read_json( $file );
        for my $section ( keys %$tmp ) {
            for my $option ( keys %{$tmp->{$section}} ) {
                $self->{opt}{$section}{$option} = $tmp->{$section}{$option} if exists $self->{opt}{$section}{$option};
            }
        }
    }
    return $self->{opt};
}


sub __read_db_config_files {
    my ( $self ) = @_;
    my $fmt = $self->{info}{conf_file_fmt};
    my $auxil = App::DBBrowser::Auxil->new( $self->{info} );
    for my $db_plugin ( @{$self->{opt}{G}{db_plugins}} ) {
        my $file = sprintf( $fmt, $db_plugin );
        if ( -f $file && -s $file ) {
            my $tmp = $auxil->__read_json( $file );
            for my $conf_sect ( keys %$tmp ) {
                my $section = $db_plugin . ( $conf_sect =~ /^\*\Q$db_plugin\E\z/ ? '' : '_' . $conf_sect );
                for my $option ( keys %{$tmp->{$conf_sect}} ) {
                    $self->{db_opt}{$section}{$option} = $tmp->{$conf_sect}{$option};
                }
            }
        }
    }
    return $self->{db_opt};
}




1;


__END__
