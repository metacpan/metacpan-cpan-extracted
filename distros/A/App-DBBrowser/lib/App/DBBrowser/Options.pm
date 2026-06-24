package # hide from PAUSE
App::DBBrowser::Options;

use warnings;
use strict;
use 5.016;

use Encode                qw( decode );
use File::Spec::Functions qw( catfile );
use FindBin               qw( $RealBin $RealScript );
#use Pod::Usage            qw( pod2usage ); # required

use Encode::Locale qw();

use Term::Choose       qw();
use Term::Choose::Util qw();

use App::DBBrowser::Auxil;
use App::DBBrowser::Options::Defaults;
use App::DBBrowser::Options::Menus;
use App::DBBrowser::Options::ReadWrite;


sub new {
    my ( $class, $info, $options ) = @_;
    bless {
        i => $info,
        o => $options
    }, $class;
}

sub __plugins {
    my ( $sf ) = @_;
    my $op_mn = App::DBBrowser::Options::Menus->new( $sf->{i}, $sf->{o} );
    my $op_rw = App::DBBrowser::Options::ReadWrite->new( $sf->{i}, $sf->{o} );
    my $groups = $op_mn->groups( undef, 1 );
    $sf->config_groups( $groups );
    #$sf->config_groups( $groups, undef, 1 );
    $op_rw->read_config_file();
}


sub __config_global {
    my ( $sf ) = @_;
    my $op_mn = App::DBBrowser::Options::Menus->new( $sf->{i}, $sf->{o} );
    my $op_rw = App::DBBrowser::Options::ReadWrite->new( $sf->{i}, $sf->{o} );
    my $groups = $op_mn->groups();
    $sf->config_groups( $groups );
    $op_rw->read_config_file();
}


sub __config_plugins {
    my ( $sf ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $op_mn = App::DBBrowser::Options::Menus->new( $sf->{i}, $sf->{o} );
    my $chosen_plugins = $sf->{o}{G}{plugins};
    my $config_old_idx = 0;

    CONFIG_PLUGIN: while ( 1 ) {
        if ( @$chosen_plugins == 1 ) {
            my $plugin = $chosen_plugins->[0];
            my $groups = $op_mn->groups( $plugin );
            $sf->config_groups( $groups, $plugin );
            last CONFIG_PLUGIN;
        }
        else {
            my @pre = ( undef );
            my $menu = [ @pre, map { '- ' . $_ } @$chosen_plugins ];
            my $prompt = 'Configure Plugins';
            # Choose
            my $config_idx = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1, default => $config_old_idx, undef => $sf->{i}{_back} }
            );
            if ( ! $config_idx ) {
                return;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $config_old_idx == $config_idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $config_old_idx = 0;
                    next CONFIG_PLUGIN;
                }
                $config_old_idx = $config_idx;
            }
            my $plugin = $menu->[$config_idx] =~ s/^-\s//r;
            my $groups = $op_mn->groups( $plugin );
            $sf->config_groups( $groups, $plugin );
        }
    }
}


sub set_options {
    my ( $sf ) = @_;
    my $op_rw = App::DBBrowser::Options::ReadWrite->new( $sf->{i}, $sf->{o} );
    $sf->{o} = $op_rw->read_config_file();
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $plugins         = '- Plugins';
    my $config_plugins  = '- Options';
    my $global_settings = '- Other';
    my $app_info        = '- App info';
    my $help            = '- Help';
    my $main_old_idx = 0;

    OPTION: while( 1 ) {
        my @pre  = ( undef, $sf->{i}{_continue} );
        my $menu = [ @pre, $plugins, $config_plugins, $global_settings, $app_info, $help ];
        # Choose
        my $main_idx = $tc->choose(
            $menu,
            { %{$sf->{i}{lyt_v}}, index => 1, default => $main_old_idx, undef => $sf->{i}{_quit} }
        );
        if ( ! $main_idx ) {
            exit();
        }
        if ( $sf->{o}{G}{menu_memory} ) {
            if ( $main_old_idx == $main_idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                $main_old_idx = 0;
                next OPTION;
            }
            $main_old_idx = $main_idx;
        }
        if ( $menu->[$main_idx] eq $sf->{i}{_continue} ) {
            return;
        }
        elsif ( $menu->[$main_idx] eq $plugins ) {
            $sf->__plugins();
        }
        elsif ( $menu->[$main_idx] eq $global_settings ) {
            $sf->__config_global();
        }
        elsif ( $menu->[$main_idx] eq $config_plugins ) {
            $sf->__config_plugins;
        }
        elsif ( $menu->[$main_idx] eq $app_info ) {
            $sf->__display_info();
        }
        elsif ( $menu->[$main_idx] eq $help ) {
            require Pod::Usage;  # ctrl-c
            Pod::Usage::pod2usage( { -exitval => 'NOEXIT', -verbose => 2 } );
        }
    }
}


sub config_groups {
    my ( $sf, $groups, $plugin ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $op_mn = App::DBBrowser::Options::Menus->new( $sf->{i}, $sf->{o} );
    my $op_rw = App::DBBrowser::Options::ReadWrite->new( $sf->{i}, $sf->{o} );
    my $driver = '';
    if ( $plugin )  {
        my $plugin_full_name = "App::DBBrowser::DB::$plugin";
        eval "require $plugin_full_name" or die $@;
        my $plugin = $plugin_full_name->new(  $sf->{i}, $sf->{o} );
        $driver = $plugin->get_db_driver();
    }
    my $lo = $op_rw->read_config_file( $driver, $plugin );
    my $prompt = '';
    my $info;
    my @pre  = ( undef );
    if ( $plugin ) {
        $info = 'Configure ' . $plugin;
        $prompt = $info;
    }
    else {
        #$prompt = 'Your choice:';
    }
    my $grp_old_idx = 0;

    GROUP: while( 1 ) {
        my ( $group, $group_prompt );
        if ( @$groups == 1 ) {
            $group = $groups->[0]{name};
            $group_prompt = $groups->[0]{text};
        }
        else {
            my $menu = [ @pre, map( $_->{text}, @$groups ) ];
            # Choose
            my $grp_idx = $tc->choose(
                $menu,
                { %{$sf->{i}{lyt_v}}, prompt => $prompt, index => 1, default => $grp_old_idx, undef => '  <=' }
            );
            if ( ! defined $grp_idx || ! defined $menu->[$grp_idx] ) {
                $op_rw->write_config_file( $lo, $plugin );
                return;
            }
            if ( $sf->{o}{G}{menu_memory} ) {
                if ( $grp_old_idx == $grp_idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                    $grp_old_idx = 0;
                    next GROUP;
                }
                $grp_old_idx = $grp_idx;
            }
            $group = $groups->[$grp_idx-@pre]{name};
            $group_prompt = $groups->[$grp_idx-@pre]{text};
        };
        if ( length $group_prompt ) {
            $group_prompt = $group_prompt =~ s/^- //r . ':';
        }
        my $sub_groups = $op_mn->sub_groups( $group, $driver );
        my $sub_group_old_idx = 0;

        OPTION: while ( 1 ) {
            my ( $section, $sub_group );
            if ( @$sub_groups == 1 ) {
                $section = $sub_groups->[0]{section};
                $sub_group = $sub_groups->[0]{name};
            }
            else {
                my @pre  = ( undef );
                my $menu = [ @pre, map( $_->{text}, @$sub_groups ) ];
                # Choose
                my $sub_group_idx = $tc->choose(
                    $menu,
                    { %{$sf->{i}{lyt_v}}, info => $info, prompt => $group_prompt,
                      index => 1, default => $sub_group_old_idx, undef => '  <=' } ##
                );
                if ( ! $sub_group_idx ) {
                    if ( @$groups == 1 ) {
                         $op_rw->write_config_file( $lo, $plugin );
                        return;
                    }
                    next GROUP;
                }
                if ( $sf->{o}{G}{menu_memory} ) {
                    if ( $sub_group_old_idx == $sub_group_idx && ! $ENV{TC_RESET_AUTO_UP} ) {
                        $sub_group_old_idx = 0;
                        next OPTION;
                    }
                    $sub_group_old_idx = $sub_group_idx;
                }
                $section = $sub_groups->[$sub_group_idx-@pre]{section};
                $sub_group = $sub_groups->[$sub_group_idx-@pre]{name};
            }
            if ( $group eq 'group_connect' ) {
                $op_mn->group_connect( $info, $lo, $section, $sub_group, $driver );
            }
            elsif ( $group eq 'group_extensions' ) {
                $op_mn->group_extensions( $info, $lo, $section, $sub_group );
            }
            elsif ( $group eq 'group_sql_settings' ) {
                $op_mn->group_sql_settings( $info, $lo, $section, $sub_group, $driver );
            }
            elsif ( $group eq 'group_create_table' ) {
                $op_mn->group_create_table( $info, $lo, $section, $sub_group );
            }
            elsif ( $group eq 'group_output' ) {
                $op_mn->group_output( $info, $lo, $section, $sub_group );
            }
            elsif ( $group eq 'group_import' ) {
                $op_mn->group_import( $info, $lo, $section, $sub_group );
            }
            elsif ( $group eq 'group_export' ) {
                $op_mn->group_export( $info, $lo, $section, $sub_group );
            }
            elsif ( $group eq 'group_misc' ) {
                $op_mn->group_misc( $info, $lo, $section, $sub_group, $driver );
            }
            elsif ( $group eq 'group_global' ) {
                $op_mn->group_global( $info, $lo, $section, $sub_group );
            }
            elsif ( $group eq 'group_select_plugins' ) {
                $op_mn->group_select_plugins( $info, $lo, $section, $sub_group );
            }
            else {
                die "Unknown group $group";
            }
            if ( @$sub_groups == 1 ) {
                if ( @$groups == 1 ) {
                    $op_rw->write_config_file( $lo, $plugin );
                    return;
                }
                else {
                    next GROUP;
                }
            }
        }
    }
}


sub __display_info {
    my ( $sf ) = @_;
    my $tc = Term::Choose->new( $sf->{i}{tc_default} );
    my $app_dir = $sf->{i}{app_dir};
    eval { $app_dir = decode( 'locale', $app_dir ) };
    my $info = 'db-browser'  . "\n\n";
    $info .= 'Version: ' . $main::VERSION . "\n\n";
    $info .= 'Path: ' . catfile( $RealBin, $RealScript ) . "\n\n";
    $info .= 'App-Dir: ' . $app_dir . "\n";
    $tc->choose( [ ' << ' ], { prompt => $info, color => 1, margin => [ 1, 1, 1, 1 ] } );
}





1;


__END__
