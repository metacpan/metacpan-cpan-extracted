package # hide from PAUSE
App::DBBrowser::Opt::DBSet;

use warnings;
use strict;
use 5.014;

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
        my ( $plugin, $key );
        if ( defined $db ) {
            $plugin = $sf->{i}{plugin};
            $key = $db;
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
                    { %{$sf->{i}{lyt_v}}, prompt => 'DB Settings for:',
                      index => 1, default => $old_idx_sec, undef => '  <=' }
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
            $key = $plugin;
        }
        my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
        my $tmp_env_var     = $plui->env_variables();
        my $env_variables   = [ map { { name => $_, values => [ 'NO', 'YES' ] } } @$tmp_env_var ]; #
        my $tmp_login_data  = $plui->read_login_data();
        my $required_fields = [ map { { name   => 'field_' . $_->{name}, values => [ 'NO', 'YES' ] } } @$tmp_login_data ];
        my $login_data      = [ grep { ! $_->{secret}                                                } @$tmp_login_data ];
        my $read_attributes = $plui->read_attributes();
        my $set_attributes  = $plui->set_attributes();
        my @groups;
        push @groups, [ 'required_fields', "- Fields"          ] if @$required_fields;
        push @groups, [ 'login_data',      "- Login Data"      ] if @$login_data;
        push @groups, [ 'env_variables',   "- ENV Variables"   ] if @$env_variables;
        push @groups, [ 'read_attributes', "- Read Attributes" ] if @$read_attributes;
        push @groups, [ 'set_attributes',  "- Set Attributes"  ] if @$set_attributes;
        if ( ! @groups ) {
            $tc->choose(
                [ 'No database settings available!' ],
                { prompt => 'Press ENTER' }
            );
            return;
        }
        push @groups, [ 'reset_db_dummy_str', "  Reset DB settings" ] if ! defined $db;
        my $prompt = defined $db ? 'DB: ' . $db : $plugin;
        my $db_opt_get = App::DBBrowser::Opt::DBGet->new( $sf->{i}, $sf->{o} );
        my $db_opt = $db_opt_get->read_db_config_files();
        my $changed = 0;
        my $old_idx_group = 0;

        GROUP: while ( 1 ) {
            my @pre = ( undef );
            my $menu = [ @pre, map( $_->[1], @groups ) ];
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
            my $group  = $groups[$idx_group-@pre][0];
            if ( $group eq 'reset_db_dummy_str' ) {
                my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
                my @databases;
                for my $key_local ( keys %$db_opt ) {
                    push @databases, $key_local if $key_local ne $plugin;
                }
                if ( ! @databases ) {
                    $tc->choose(
                        [ 'No databases with customized settings.' ],
                        { prompt => 'Press ENTER' }
                    );
                    next GROUP;
                }
                my $db_to_reset = $tu->choose_a_subset(
                    [ sort @databases ],
                    { cs_label => 'DB settings to reset: ', layout => 2, cs_separator => "\n", cs_begin => "\n",
                      prompt => "\nChoose:", confirm => $sf->{i}{confirm}, back => $sf->{i}{back} }
                );
                if ( ! $db_to_reset->[0] ) {
                    next GROUP;
                }
                for my $db ( @$db_to_reset ) {
                    delete $db_opt->{$db};
                }
                $sf->{write_config}++;
            }
            elsif ( $group eq 'required_fields' ) {
                my $sub_menu = [];
                for my $item ( @$required_fields ) {
                    my $opt = $item->{name};
                    my $prompt = '- ' . $item->{name} =~ s/^field_//r;
                    push @$sub_menu, [ $opt, $prompt, $item->{values} ];
                            # db specific               # global
                    $db_opt->{$key}{$opt} //= $db_opt->{$plugin}{$opt} // 1; # by default enabled
                }
                my $prompt = sprintf "%s\n%s:", $plugin, $group;
                $sf->__settings_menu_wrap_db( $db_opt, $key, $sub_menu, $prompt );
            }
            elsif ( $group eq 'login_data' ) {
               for my $item ( @$login_data ) {
                    my $opt = $item->{name};
                    if ( ! length $db_opt->{$key}{$opt} ) {
                        $db_opt->{$key}{$opt} = $db_opt->{$plugin}{$opt};
                    }
                }
                my $prompt = sprintf "%s\n%s:", $plugin, $group;
                $sf->__group_readline_db( $db_opt, $key, $login_data, $prompt );
            }
            elsif ( $group eq 'read_attributes' ) {
               for my $item ( @$read_attributes ) {
                    my $opt = $item->{name};
                    if ( ! length $db_opt->{$key}{$opt} ) {
                        if ( length $db_opt->{$plugin}{$opt} ) {
                            $db_opt->{$key}{$opt} = $db_opt->{$plugin}{$opt};
                        }
                        elsif ( length $item->{default} ) {
                            $db_opt->{$key}{$opt} = $item->{default};
                        }
                    }
                }
                my $prompt = sprintf "%s\n%s:", $plugin, $group;
                $sf->__group_readline_db( $db_opt, $key, $read_attributes, $prompt );
            }
            elsif ( $group eq 'env_variables' ) {
                my $sub_menu = [];
                for my $item ( @$env_variables ) {
                    my $opt = $item->{name};
                    my $prompt = '- ' . $item->{name};
                    push @$sub_menu, [ $opt, $prompt, $item->{values} ];
                    $db_opt->{$key}{$opt} //= $db_opt->{$plugin}{$opt} // 0; # by default disabled
                }
                my $prompt = sprintf "%s\n%s:", $plugin, $group;
                $sf->__settings_menu_wrap_db( $db_opt, $key, $sub_menu, $prompt );
            }
            elsif ( $group eq 'set_attributes' ) {
                my $sub_menu = [];
                for my $item ( @$set_attributes ) {
                    my $opt = $item->{name};
                    my $prompt = '- ' . $item->{name};
                    push @$sub_menu, [ $opt, $prompt, $item->{values} ];
                    $db_opt->{$key}{$opt} //= $db_opt->{$plugin}{$opt} // $item->{values}[$item->{default}];
                }
                my $prompt = sprintf "%s\n%s:", $plugin, $group;
                $sf->__settings_menu_wrap_db( $db_opt, $key, $sub_menu, $prompt );
            }
        }
    }
}


sub __settings_menu_wrap_db {
    my ( $sf, $db_opt, $key, $sub_menu, $prompt ) = @_;
    my $tu = Term::Choose::Util->new( $sf->{i}{tcu_default} );
    my $changed = $tu->settings_menu(
        $sub_menu, $db_opt->{$key},
        { prompt => $prompt, back => $sf->{i}{_back}, confirm => $sf->{i}{_confirm} }
    );
    return if ! $changed;
    $sf->{write_config}++;
}


sub __group_readline_db {
    my ( $sf, $db_opt, $key, $items, $prompt ) = @_;
    my $list = [ map { [ $_->{name}, $db_opt->{$key}{$_->{name}} ] } @{$items} ];
    my $tf = Term::Form->new( $sf->{i}{tf_default} );
    my $new_list = $tf->fill_form(
        $list,
        { prompt => $prompt, confirm => $sf->{i}{confirm}, back => $sf->{i}{back} }
    );
    if ( $new_list ) {
        for my $i ( 0 .. $#$items ) {
            $db_opt->{$key}{$items->[$i]{name}} = $new_list->[$i][1];
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
