package # hide from PAUSE
App::DBBrowser::Opt::DBGet;

use warnings;
use strict;
use 5.014;

use App::DBBrowser::Auxil;
use App::DBBrowser::DB;


sub new {
    my ( $class, $info, $options ) = @_;
    bless {
        i => $info,
        o => $options,
    }, $class;
}


sub read_db_config_files {
    my ( $sf ) = @_;
    my $ax = App::DBBrowser::Auxil->new( $sf->{i}, $sf->{o}, {} );
    my $plugin = $sf->{i}{plugin};
    $plugin =~ s/^App::DBBrowser::DB:://;
    my $file_fs = sprintf( $sf->{i}{conf_file_fmt}, $plugin );
    my $db_opt;
    if ( -f $file_fs && -s $file_fs ) {
        $db_opt = $ax->read_json( $file_fs ) // {};
    }
    return $db_opt;
}


sub get_set_attributes {
    my ( $sf, $db, $db_opt ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $plugin = $sf->{i}{plugin};
    my $prepared_set_attrs = {};
    # attributes added by hand to the config file:
    # added attribues are only used if they have entries in the set_attributes method
    my $set_attributes = $plui->set_attributes();

    for my $set_attribute ( @$set_attributes )  {
        my $name = $set_attribute->{name};
        my $idx = $db_opt->{$db//''}{$name} // $db_opt->{$plugin}{$name} // $set_attribute->{default};
        $prepared_set_attrs->{$name} = $set_attribute->{values}[$idx];
        if ( $prepared_set_attrs->{$name} =~ /^(\d+)\s/ ) { # e.g.: '5 DBD_SQLITE_STRING_MODE_UNICODE_FALLBACK'
            $prepared_set_attrs->{$name} = $1;
        }

    }
    return $prepared_set_attrs;
}


sub get_read_attributes {
    my ( $sf, $db, $db_opt ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $plugin = $sf->{i}{plugin};
    my $prepared_read_attrs = {};
    my $read_attributes = $plui->read_attributes();

    for my $read_attribute ( @$read_attributes )  {
        my $name = $read_attribute->{name};
        if ( length $db_opt->{$db//''}{$name} ) {
            $prepared_read_attrs->{$name} = $db_opt->{$db//''}{$name};
        }
        elsif ( length $db_opt->{$plugin}{$name} ) {
            $prepared_read_attrs->{$name} = $db_opt->{$plugin}{$name};
        }
        elsif ( length $read_attribute->{default} ) {
            $prepared_read_attrs->{$name} = $read_attribute->{default};
        }
    }
    return $prepared_read_attrs;
}


sub get_login_data {
    my ( $sf, $db, $db_opt ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $plugin = $sf->{i}{plugin};
    my $arg = $plui->read_login_data();
    my $login_data = {};

    for my $item ( @$arg ) {
        my $name = $item->{name};
        my $secret = $item->{secret};
        my $field_is_required = $db_opt->{$db//''}{'field_' . $name} // $db_opt->{$plugin}{'field_' . $name} // 1; # set to "required" (1) if undefined
        if ( $field_is_required ) {
            if ( $sf->{i}{login_error} ) {
                $login_data->{$name}{default} = undef; # if a login error occured, the user has to enter the arguments by hand
                delete $sf->{i}{login_error};
            }
            else {
                if ( length $db_opt->{$db//''}{$name} ) {
                    $login_data->{$name}{default} = $db_opt->{$db//''}{$name};
                }
                else {
                    $login_data->{$name}{default} = $db_opt->{$plugin}{$name};
                }
            }
            $login_data->{$name}{secret} = $secret;
        }
    }
    return $login_data;
}


sub enabled_env_vars {
    my ( $sf, $db, $db_opt ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $plugin = $sf->{i}{plugin};
    my $env_vars = $plui->env_variables();
    my $enabled_env_vars = {};
    for my $env_var ( @$env_vars ) {
        $enabled_env_vars->{$env_var} = $db_opt->{$db//''}{$env_var} // $db_opt->{$sf->{i}{plugin}}{$env_var};
    }
    return $enabled_env_vars;
}



1;


__END__
