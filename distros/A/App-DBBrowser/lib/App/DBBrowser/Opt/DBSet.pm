package # hide from PAUSE
App::DBBrowser::Opt::DBSet;

use warnings;
use strict;
use 5.010001;

use File::Spec::Functions qw( catfile );

use Term::Choose       qw();
use Term::Choose::Util qw();
use Term::Form         qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;
use App::DBBrowser::Opt::DBGet;


sub new {
    my ( $class, $info, $options ) = @_;
    bless {
        i => $info,
        o => $options,
    }, $class;
}


sub database_setting {
    my ( $sf, $db ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
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
                my $menu = [ undef, map( "- $_", @{$sf->{o}{G}{plugins}} ) ];
                # Choose
                my $idx_sec = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, index => 1, default => $old_idx_sec, undef => '  <=' }
                );
                if ( ! defined $idx_sec || ! defined $menu->[$idx_sec] ) {
                    return;
                }
                if ( $sf->{o}{G}{menu_memory} ) {
                    if ( $old_idx_sec == $idx_sec && ! $ENV{TC_RESET_AUTO_UP} ) {
                        $old_idx_sec = 0;
                        next SECTION;
                    }
                    $old_idx_sec = $idx_sec;
                }
                $plugin = $menu->[$idx_sec];
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
                    name   => 'field_' . $_->{name},
                    prompt => exists $_->{prompt} ? $_->{prompt} : $_->{name},
                    values => [ 'NO', 'YES' ]
                } } @$login_data ],
            arguments => [
                    grep { ! $_->{secret} } @$login_data
                ],
            env_variables => [ map { { #
                    name   => $_,
                    prompt => $_,
                    values => [ 'NO', 'YES' ]
                } } @$env_var ],

            attributes => $attr,
        };
        my @groups;
        push @groups, [ 'required',      "- Fields"        ] if @{$items->{required}};
        push @groups, [ 'arguments',     "- Login Data"    ] if @{$items->{arguments}};
        push @groups, [ 'env_variables', "- ENV Variables" ] if @{$items->{env_variables}};
        push @groups, [ 'attributes',    "- Attributes"    ] if @{$items->{attributes}};
        if ( ! @groups ) {
            $tc->choose(
                [ 'No database settings available!' ],
                { prompt => 'Press ENTER' }
            );
            return;
        }
        my $prompt = defined $db ? 'DB: ' . $db . '' : '' . $plugin . '';
        my $db_opt_get = App::DBBrowser::Opt::DBGet->new( $sf->{i}, $sf->{o} );
        my $db_opt = $db_opt_get->read_db_config_files();

        my $changed = 0;
        my $old_idx_group = 0;

        GROUP: while ( 1 ) {
            my $reset = '  Reset DB';
            my @pre = ( undef );
            my $menu = [ @pre, map( $_->[1], @groups ) ];
            push @$menu, $reset if ! defined $db;
            # Choose
            my $idx_group = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1, default => $old_idx_group, undef => '  <=' }
            );
            if ( ! defined $idx_group || ! defined $menu->[$idx_group] ) {
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
                $old_idx_group = $idx_group;
            }
            if ( $menu->[$idx_group] eq $reset ) {
                my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
                my @databases;
                for my $section ( keys %$db_opt ) {
                    push @databases, $section if $section ne $plugin;
                }
                if ( ! @databases ) {
                    $tc->choose(
                        [ 'No databases with customized settings.' ],
                        { prompt => 'Press ENTER' }
                    );
                    next GROUP;
                }
                my $menu = $tu->choose_a_subset(
                    [ sort @databases ],
                    { cs_label => 'Reset DB: ' }
                );
                if ( ! $menu->[0] ) {
                    next GROUP;
                }
                for my $db ( @$menu ) {
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
                              # db specific                      # global
                    $db_opt->{$section}{$required} //= $db_opt->{$plugin}{$required} // 1; # the default: "required" is true (1)
                }
                my $prompt = 'Required fields (' . $plugin . '):';
                $sf->__settings_menu_wrap_db( $db_opt, $section, $sub_menu, $prompt );
                next GROUP;
            }
            elsif ( $group eq 'arguments' ) {
               for my $item ( @{$items->{$group}} ) {
                    my $opt = $item->{name};
                    $db_opt->{$section}{$opt} //= $db_opt->{$plugin}{$opt};
                }
                my $prompt = 'Default login data (' . $plugin . ')';
                $sf->__group_readline_db( $db_opt, $section, $items->{$group}, $prompt );
            }
            elsif ( $group eq 'env_variables' ) {
                my $sub_menu = [];
                for my $item ( @{$items->{$group}} ) {
                    my $env_variable = $item->{name};
                    push @$sub_menu, [ $env_variable, '- ' . $item->{prompt}, $item->{values} ];
                    $db_opt->{$section}{$env_variable} //= $db_opt->{$plugin}{$env_variable} // 0; # default: "disabled" (0)
                }
                my $prompt = 'Use ENV variables (' . $plugin . '):';
                $sf->__settings_menu_wrap_db( $db_opt, $section, $sub_menu, $prompt );
                next GROUP;
            }
            elsif ( $group eq 'attributes' ) {
                my $sub_menu = [];
                for my $item ( @{$items->{$group}} ) {
                    my $opt = $item->{name};
                    my $prompt = '- ' . ( exists $item->{prompt} ? $item->{prompt} : $item->{name} );
                    push @$sub_menu, [ $opt, $prompt, $item->{values} ];
                    $db_opt->{$section}{$opt} //= $db_opt->{$plugin}{$opt} // $item->{values}[$item->{default}];
                }
                my $prompt = 'Options ' . $plugin . ':';
                $sf->__settings_menu_wrap_db( $db_opt, $section, $sub_menu, $prompt );
                next GROUP;
            }
        }
    }
}


sub __settings_menu_wrap_db {
    my ( $sf, $db_opt, $section, $sub_menu, $prompt ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $changed = $tu->settings_menu(
        $sub_menu, $db_opt->{$section},
        { prompt => $prompt, back => $sf->{i}{_back}, confirm => $sf->{i}{_confirm} }
    );
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
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $new_list = $tf->fill_form(
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
    my $file_fs = sprintf( $sf->{i}{conf_file_fmt}, $plugin );
    if ( defined $db_opt && %$db_opt ) {
        $ax->write_json( $file_fs, $db_opt );
    }
}





1;


__END__
