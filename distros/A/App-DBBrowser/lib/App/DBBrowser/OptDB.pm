package # hide from PAUSE
App::DBBrowser::OptDB;

use warnings;
use strict;
use 5.008003;

use File::Spec::Functions qw( catfile );

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_subset settings_menu );
use Term::Form         qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;


sub new {
    my ( $class, $info, $options ) = @_;
    bless {
        i => $info,
        o => $options,
        conf_file_fmt => catfile( $info->{app_dir}, 'config_%s.json' ),
    }, $class;
}


sub connect_parameter {
    my ( $sf, $db_opt, $db ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $plugin = $sf->{i}{plugin};
    my $para = {};

    my $env_vars = $plui->env_variables();
    for my $env_var ( @$env_vars ) {
        if ( ! defined $db || ! defined $db_opt->{$db}{$env_var} ) {
            # use global
            $para->{use_env_var}{$env_var} = $db_opt->{$plugin}{$env_var};
        }
        else {
            $para->{use_env_var}{$env_var} = $db_opt->{$db}{$env_var};
        }
    }

    my $attrs = $plui->set_attributes();
    # attributes added by hand to the config file: attribues are
    # only used if they have entries in the set_attributes method
    for my $attr ( @$attrs ) {
        my $name = $attr->{name};
        if ( ! defined $db || ! defined $db_opt->{$db}{$name} ) {
            if ( ! defined $db_opt->{$plugin}{$name} ) {
                # set global to default
                $db_opt->{$plugin}{$name} = $attr->{values}[$attr->{default}];
            }
            # use global
            $para->{attributes}{$name} = $db_opt->{$plugin}{$name};
        }
        else {
            $para->{attributes}{$name} = $db_opt->{$db}{$name};
        }
    }

    my $arg = $plui->read_arguments();
    for my $item ( @$arg ) {
        my $name = $item->{name};
        my $required = 'field_' . $name;
        $para->{secret}{$name} = $item->{secret};
        if ( ! defined $db || ! defined $db_opt->{$db}{$required} ) {
            if ( ! defined $db_opt->{$plugin}{$required} ) {
                # set global to default
                $db_opt->{$plugin}{$required} = 1; # All fields required by default
            }
            # use gloabl
            $para->{required}{$name} = $db_opt->{$plugin}{$required};
        }
        else {
            $para->{required}{$name} = $db_opt->{$db}{$required};
        }
        # if a login error occurred, the next time the user has to enter the arguments by hand
        if ( ! $sf->{i}{login_error} ) {
            if ( ! defined $db || ! defined $db_opt->{$db}{$name} ) {
                # use global
                $para->{arguments}{$name} = $db_opt->{$plugin}{$name};
            }
            else {
                $para->{arguments}{$name} = $db_opt->{$db}{$name};
            }
        }
    }
    if ( @$env_vars + @$attrs + @$arg ) {
        $sf->{i}{db_settings} = 1;
    }
    else {
        $sf->{i}{db_settings} = 0;
    }
    if ( exists $sf->{i}{login_error} ) {
        delete $sf->{i}{login_error};
    }
    return $para;
}


sub database_setting {
    my ( $sf, $db ) = @_;
    my $old_idx_sec = 0;

    SECTION: while ( 1 ) {
        my ( $plugin, $section );
        if ( defined $db ) {
            $plugin = $sf->{i}{plugin};
            $section = $db;
        }
        else {
            if ( @{$sf->{o}{G}{plugins}} == 1 ) {
                $plugin = $sf->{o}{G}{plugins}[0];
            }
            else {
                $ENV{TC_RESET_AUTO_UP} = 0;
                my $choices = [ undef, map( "- $_", @{$sf->{o}{G}{plugins}} ) ];
                # Choose
                my $idx_sec = choose(
                    $choices,
                    { %{$sf->{i}{lyt_v_clear}}, undef => '  <=', default => $old_idx_sec, index => 1 }
                );
                if ( ! defined $idx_sec || ! defined $choices->[$idx_sec] ) {
                    return;
                }
                if ( $sf->{o}{G}{menu_memory} ) {
                    if ( $old_idx_sec == $idx_sec && ! $ENV{TC_RESET_AUTO_UP} ) {
                        $old_idx_sec = 0;
                        next SECTION;
                    }
                    else {
                        $old_idx_sec = $idx_sec;
                    }
                }
                delete $ENV{TC_RESET_AUTO_UP};
                $plugin = $choices->[$idx_sec];
                $plugin =~ s/^-\ //;
            }
            $plugin = 'App::DBBrowser::DB::' . $plugin;
            $sf->{i}{plugin} = $plugin;
            $section = $plugin;
        }
        my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
        my $env_var    = $plui->env_variables();
        my $login_data = $plui->read_arguments();
        my $attr       = $plui->set_attributes();
        my $items = {
            required => [ map { {
                    name         => 'field_' . $_->{name},
                    prompt       => exists $_->{prompt} ? $_->{prompt} : $_->{name},
                    values => [ 'NO', 'YES' ]
                } } @$login_data ],
            env_variables => [ map { { #
                    name         => $_,
                    prompt       => $_,
                    values => [ 'NO', 'YES' ]
                } } @$env_var ],
            arguments => [
                    grep { ! $_->{secret} } @$login_data
                ],
            attributes => $attr,
        };
        my @groups;
        push @groups, [ 'required',      "- Fields"        ] if @{$items->{required}};
        push @groups, [ 'env_variables', "- ENV Variables" ] if @{$items->{env_variables}};
        push @groups, [ 'arguments',     "- Login Data"    ] if @{$items->{arguments}};
        push @groups, [ 'attributes',    "- Attributes"    ] if @{$items->{attributes}};
        if ( ! @groups ) {
            return 0;
        }
        my $prompt = defined $db ? 'DB: ' . $db . '' : '' . $plugin . '';
        my $db_opt = $sf->read_db_config_files();

        my $changed = 0;
        my $old_idx_group = 0;

        GROUP: while ( 1 ) {
            my $reset = '  Reset DB';
            my @pre = ( undef );
            my $choices = [ @pre, map( $_->[1], @groups ) ];
            push @$choices, $reset if ! defined $db;
            # Choose
            $ENV{TC_RESET_AUTO_UP} = 0;
            my $idx_group = choose(
                $choices,
                { %{$sf->{i}{lyt_v_clear}}, prompt => $prompt, index => 1,
                  default => $old_idx_group, undef => '  <=' }
            );
            if ( ! defined $idx_group || ! defined $choices->[$idx_group] ) {
                if ( $sf->{write_config} ) {
                    $sf->__write_db_config_files( $db_opt );
                    delete $sf->{write_config};
                    $changed++;
                }
                next SECTION if ! $db && @{$sf->{o}{G}{plugins}} > 1;
                return $changed;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $old_idx_group == $idx_group && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $old_idx_group = 0;
                    next GROUP;
                }
                else {
                    $old_idx_group = $idx_group;
                }
            }
            delete $ENV{TC_RESET_AUTO_UP};
            if ( $choices->[$idx_group] eq $reset ) {
                my @databases;
                for my $section ( keys %$db_opt ) {
                    push @databases, $section if $section ne $plugin;
                }
                if ( ! @databases ) {
                    choose(
                        [ 'No databases with customized settings.' ],
                        { %{$sf->{i}{lyt_m}}, prompt => 'Press ENTER' }
                    );
                    next GROUP;
                }
                my $choices = choose_a_subset(
                    [ sort @databases ],
                    { p_new => 'Reset DB: ', mouse => $sf->{o}{table}{mouse} }
                );
                if ( ! $choices->[0] ) {
                    next GROUP;
                }
                for my $db ( @$choices ) {
                    delete $db_opt->{$db};
                }
                $sf->{write_config}++;
                next GROUP;;
            }
            my $group  = $groups[$idx_group-@pre][0];
            if ( $group eq 'required' ) {
                my $sub_menu = [];
                for my $item ( @{$items->{$group}} ) {
                    my $required = $item->{name};
                    push @$sub_menu, [ $required, '- ' . $item->{prompt}, $item->{values} ];
                    if ( ! defined $db_opt->{$section}{$required} ) {
                        if ( defined $db_opt->{$plugin}{$required} ) {
                            # set to global (if $section == $db )
                            $db_opt->{$section}{$required} = $db_opt->{$plugin}{$required};
                        }
                        else {
                            # set to default
                            $db_opt->{$section}{$required} = 1;  # All fields required by default
                        }
                    }
                }
                my $prompt = 'Required fields (' . $plugin . '):';
                $sf->__settings_menu_wrap_db( $db_opt, $section, $sub_menu, $prompt );
                next GROUP;
            }
            elsif ( $group eq 'env_variables' ) {
                my $sub_menu = [];
                for my $item ( @{$items->{$group}} ) {
                    my $env_variable = $item->{name};
                    push @$sub_menu, [ $env_variable, '- ' . $item->{prompt}, $item->{values} ];
                    if ( ! defined $db_opt->{$section}{$env_variable} ) {
                        if ( defined $db_opt->{$plugin}{$env_variable} ) {
                            # set to global
                            $db_opt->{$section}{$env_variable} = $db_opt->{$plugin}{$env_variable};
                        }
                        else {
                            # set to default
                            $db_opt->{$section}{$env_variable} = 0;
                        }
                    }
                }
                my $prompt = 'Use ENV variables (' . $plugin . '):';
                $sf->__settings_menu_wrap_db( $db_opt, $section, $sub_menu, $prompt );
                next GROUP;
            }
            elsif ( $group eq 'arguments' ) {
               for my $item ( @{$items->{$group}} ) {
                    my $opt = $item->{name};
                    if ( ! defined $db_opt->{$section}{$opt} ) {
                        if ( defined $db_opt->{$plugin}{$opt} ) {
                            # set to global
                            $db_opt->{$section}{$opt} = $db_opt->{$plugin}{$opt};
                        }
                    }
                }
                my $prompt = 'Default login data (' . $plugin . ')';
                $sf->__group_readline_db( $db_opt, $section, $items->{$group}, $prompt );
            }
            elsif ( $group eq 'attributes' ) {
                my $sub_menu = [];
                for my $item ( @{$items->{$group}} ) {
                    my $opt = $item->{name};
                    my $prompt = '- ' . ( exists $item->{prompt} ? $item->{prompt} : $item->{name} );
                    push @$sub_menu, [ $opt, $prompt, $item->{values} ];
                    if ( ! defined $db_opt->{$section}{$opt} ) {
                        if ( defined $db_opt->{$plugin}{$opt} ) {
                            # set to global
                            $db_opt->{$section}{$opt} = $db_opt->{$plugin}{$opt};
                        }
                        else {
                            # set to default
                            $db_opt->{$section}{$opt} = $item->{values}[$item->{default}];
                        }
                    }
                }
                my $prompt = 'Options (' . $plugin . '):';
                $sf->__settings_menu_wrap_db( $db_opt, $section, $sub_menu, $prompt );
                next GROUP;
            }
        }
    }
}


sub __settings_menu_wrap_db {
    my ( $sf, $db_opt, $section, $sub_menu, $prompt ) = @_;
    my $changed = settings_menu( $sub_menu, $db_opt->{$section}, { prompt => $prompt, mouse => $sf->{o}{table}{mouse} } );
    return if ! $changed;
    $sf->{write_config}++;
}


sub __group_readline_db {
    my ( $sf, $db_opt, $section, $items, $prompt ) = @_;
    my $list = [ map {
        [
            exists $_->{prompt} ? $_->{prompt} : $_->{name},
            $db_opt->{$section}{$_->{name}}
        ]
    } @{$items} ];
    my $trs = Term::Form->new();
    my $new_list = $trs->fill_form(
        $list,
        { prompt => $prompt, auto_up => 2, confirm => $sf->{i}{confirm}, back => $sf->{i}{back} }
    );
    if ( $new_list ) {
        for my $i ( 0 .. $#$items ) {
            $db_opt->{$section}{$items->[$i]{name}} = $new_list->[$i][1];
        }
        $sf->{write_config}++;
    }
}


sub __write_db_config_files {
    my ( $sf, $db_opt ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, {} );
    my $plugin = $sf->{i}{plugin};
    $plugin=~ s/^App::DBBrowser::DB:://;
    my $file_name = sprintf( $sf->{conf_file_fmt}, $plugin );
    if ( defined $db_opt && %$db_opt ) {
        $ax->write_json( $file_name, $db_opt );
    }
}


sub read_db_config_files {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, {} );
    my $plugin = $sf->{i}{plugin};
    $plugin =~ s/^App::DBBrowser::DB:://;
    my $file_name = sprintf( $sf->{conf_file_fmt}, $plugin );
    my $db_opt;
    if ( -f $file_name && -s $file_name ) {
        $db_opt = $ax->read_json( $file_name ) || {};
    }
    return $db_opt;
}




1;


__END__
