package # hide from PAUSE
App::DBBrowser::OptDB;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

our $VERSION = '2.006';

use File::Basename qw( basename );

use Term::Choose       qw( choose );
use Term::Choose::Util qw( choose_a_subset settings_menu );
use Term::Form         qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;


sub new {
    my ( $class, $info, $opt ) = @_;
    bless { i => $info, o => $opt }, $class;
}


sub connect_parameter {
    my ( $sf, $db_o, $db ) = @_;
    my $obj_db = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $plugin = $sf->{i}{plugin};
    my $cp = {
#        use_env_var => {},
#        required    => {},
#        secret      => {},
#        arguments   => {},
#        attributes  => {},
    };

    my $env_vars = $obj_db->env_variables();
    for my $env_var ( @$env_vars ) {
        if ( ! defined $db || ! defined $db_o->{$db}{$env_var} ) {
            # use global
            $cp->{use_env_var}{$env_var} = $db_o->{$plugin}{$env_var};
        }
        else {
            $cp->{use_env_var}{$env_var} = $db_o->{$db}{$env_var};
        }
    }

    my $attrs = $obj_db->set_attributes();
    # attributes added by hand to the config file: attribues are
    # only used if they have entries in the set_attributes method
    for my $attr ( @$attrs ) {
        my $name = $attr->{name};
        if ( ! defined $db || ! defined $db_o->{$db}{$name} ) {
            if ( ! defined $db_o->{$plugin}{$name} ) {
                # set global to default
                $db_o->{$plugin}{$name} = $attr->{values}[$attr->{default}];
            }
            # use global
            $cp->{attributes}{$name} = $db_o->{$plugin}{$name};
        }
        else {
            $cp->{attributes}{$name} = $db_o->{$db}{$name};
        }
    }

    my $arg = $obj_db->read_arguments();
    for my $item ( @$arg ) {
        my $name = $item->{name};
        my $required = 'field_' . $name;
        $cp->{secret}{$name} = $item->{secret};
        if ( ! defined $db || ! defined $db_o->{$db}{$required} ) {
            if ( ! defined $db_o->{$plugin}{$required} ) {
                # set global to default
                $db_o->{$plugin}{$required} = 1; # All fields required by default
            }
            # use gloabl
            $cp->{required}{$name} = $db_o->{$plugin}{$required};
        }
        else {
            $cp->{required}{$name} = $db_o->{$db}{$required};
        }
        # if a login error occurred, the next time the user has to enter the arguments by hand
        if ( ! $sf->{i}{login_error} ) {
            if ( ! defined $db || ! defined $db_o->{$db}{$name} ) {
                # use global
                $cp->{arguments}{$name} = $db_o->{$plugin}{$name};
            }
            else {
                $cp->{arguments}{$name} = $db_o->{$db}{$name};
            }
        }
    }
    if ( exists $sf->{i}{login_error} ) {
        delete $sf->{i}{login_error};
    }
    return $cp;
}



sub database_setting {
    my ( $sf, $db ) = @_;
    my $old_idx_sec = 0;

    SECTION: while ( 1 ) {
        my ( $plugin, $section );
        #my ( $driver, $plugin, $section );
        if ( defined $db ) {
            $plugin = $sf->{i}{plugin};
            #$driver = $sf->{i}{driver};
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
                    { %{$sf->{i}{lyt_3}}, undef => $sf->{i}{back_config}, default => $old_idx_sec, index => 1 }
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
        my $obj_db = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
        #$driver = $obj_db->driver() if ! $driver;
        my $env_var    = $obj_db->env_variables();
        my $login_data = $obj_db->read_arguments();
        my $attr       = $obj_db->set_attributes();
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
        push @groups, [ 'required',      "- Fields"             ] if @{$items->{required}};
        push @groups, [ 'env_variables', "- ENV Variables"      ] if @{$items->{env_variables}};
        push @groups, [ 'arguments',     "- Login Data"         ] if @{$items->{arguments}};
        push @groups, [ 'attributes',    "- Attributes"         ] if @{$items->{attributes}};
        my $prompt = defined $db ? 'DB: "' . $db . '"' : '"' . $plugin . '"';
        my $db_o = $sf->__read_db_config_files();

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
                { %{$sf->{i}{lyt_3}}, prompt => $prompt, index => 1,
                  default => $old_idx_group, undef => $sf->{i}{back_config} }
            );
            if ( ! defined $idx_group || ! defined $choices->[$idx_group] ) {
                if ( $sf->{i}{write_config} ) {
                    $sf->__write_db_config_files( $db_o );
                    delete $sf->{i}{write_config};
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
                for my $section ( keys %$db_o ) {
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
                    delete $db_o->{$db};
                }
                $sf->{i}{write_config}++;
                next GROUP;;
            }
            my $group  = $groups[$idx_group-@pre][0];
            if ( $group eq 'required' ) {
                my $sub_menu = [];
                for my $item ( @{$items->{$group}} ) {
                    my $required = $item->{name};
                    push @$sub_menu, [ $required, '- ' . $item->{prompt}, $item->{values} ];
                    if ( ! defined $db_o->{$section}{$required} ) {
                        if ( defined $db_o->{$plugin}{$required} ) {
                            # set to global (if $section == $db )
                            $db_o->{$section}{$required} = $db_o->{$plugin}{$required};
                        }
                        else {
                            # set to default
                            $db_o->{$section}{$required} = 1;  # All fields required by default
                        }
                    }
                }
                my $prompt = 'Required fields (' . $plugin . '):';
                $sf->__settings_menu_wrap_db( $db_o, $section, $sub_menu, $prompt );
                next GROUP;
            }
            elsif ( $group eq 'env_variables' ) {
                my $sub_menu = [];
                for my $item ( @{$items->{$group}} ) {
                    my $env_variable = $item->{name};
                    push @$sub_menu, [ $env_variable, '- ' . $item->{prompt}, $item->{values} ];
                    if ( ! defined $db_o->{$section}{$env_variable} ) {
                        if ( defined $db_o->{$plugin}{$env_variable} ) {
                            # set to global
                            $db_o->{$section}{$env_variable} = $db_o->{$plugin}{$env_variable};
                        }
                        else {
                            # set to default
                            $db_o->{$section}{$env_variable} = 0;
                        }
                    }
                }
                my $prompt = 'Use ENV variables (' . $plugin . '):';
                $sf->__settings_menu_wrap_db( $db_o, $section, $sub_menu, $prompt );
                next GROUP;
            }
            elsif ( $group eq 'arguments' ) {
               for my $item ( @{$items->{$group}} ) {
                    my $opt = $item->{name};
                    if ( ! defined $db_o->{$section}{$opt} ) {
                        if ( defined $db_o->{$plugin}{$opt} ) {
                            # set to global
                            $db_o->{$section}{$opt} = $db_o->{$plugin}{$opt};
                        }
                    }
                }
                my $prompt = 'Default login data (' . $plugin . '):';
                $sf->__group_readline_db( $db_o, $section, $items->{$group}, $prompt );
            }
            elsif ( $group eq 'attributes' ) {
                my $sub_menu = [];
                for my $item ( @{$items->{$group}} ) {
                    my $opt = $item->{name};
                    my $prompt = '- ' . ( exists $item->{prompt} ? $item->{prompt} : $item->{name} );
                    push @$sub_menu, [ $opt, $prompt, $item->{values} ];
                    if ( ! defined $db_o->{$section}{$opt} ) {
                        if ( defined $db_o->{$plugin}{$opt} ) {
                            # set to global
                            $db_o->{$section}{$opt} = $db_o->{$plugin}{$opt};
                        }
                        else {
                            # set to default
                            $db_o->{$section}{$opt} = $item->{values}[$item->{default}];
                        }
                    }
                }
                my $prompt = 'Options (' . $plugin . '):';
                $sf->__settings_menu_wrap_db( $db_o, $section, $sub_menu, $prompt );
                next GROUP;
            }
        }
    }
}


sub __settings_menu_wrap_db {
    my ( $sf, $db_o, $section, $sub_menu, $prompt ) = @_;
    my $changed = settings_menu( $sub_menu, $db_o->{$section}, { prompt => $prompt, mouse => $sf->{o}{table}{mouse} } );
    return if ! $changed;
    $sf->{i}{write_config}++;
}

sub __group_readline_db {
    my ( $sf, $db_o, $section, $items, $prompt ) = @_;
    my $list = [ map {
        [
            exists $_->{prompt} ? $_->{prompt} : $_->{name},
            $db_o->{$section}{$_->{name}}
        ]
    } @{$items} ];
    my $trs = Term::Form->new();
    my $new_list = $trs->fill_form(
        $list,
        { prompt => $prompt, auto_up => 2, confirm => $sf->{i}{_confirm}, back => $sf->{i}{_back} }
    );
    if ( $new_list ) {
        for my $i ( 0 .. $#$items ) {
            $db_o->{$section}{$items->[$i]{name}} = $new_list->[$i][1];
        }
        $sf->{i}{write_config}++;
    }
}


sub __write_db_config_files {
    my ( $sf, $db_o ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $plugin = $sf->{i}{plugin};
    $plugin=~ s/^App::DBBrowser::DB:://;
    my $file_name = sprintf( $sf->{i}{conf_file_fmt}, $plugin );
    $file_name=~ s/^App::DBBrowser::DB:://;
    if ( defined $db_o && %$db_o ) {
        $ax->write_json( $file_name, $db_o );
    }
}


sub __read_db_config_files {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o} );
    my $plugin = $sf->{i}{plugin};
    $plugin=~ s/^App::DBBrowser::DB:://;
    my $file_name = sprintf( $sf->{i}{conf_file_fmt}, $plugin );
    my $db_o;
    if ( -f $file_name && -s $file_name ) {
        $db_o = $ax->read_json( $file_name ) || {};
    }
    return $db_o;
}




1;


__END__
