package # hide from PAUSE
App::DBBrowser::Opt::DBGet;

use warnings;
use strict;
use 5.010001;

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


sub attributes {
    my ( $sf, $db, $db_opt ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $plugin = $sf->{i}{plugin};
    # attributes added by hand to the config file:
    # added attribues are only used if they have entries in the set_attributes method
    my $attributes = $plui->set_attributes();
    my $prepared_attrs = {};
    for my $attribute ( @$attributes )  {
        my $name = $attribute->{name};
        my $idx = $db_opt->{$db//''}{$name} // $db_opt->{$plugin}{$name} // $attribute->{default};
        $prepared_attrs->{$name} = $attribute->{values}[$idx];
        if ( $prepared_attrs->{$name} =~ /^(\d+)\s/ ) { # e.g.: '5 DBD_SQLITE_STRING_MODE_UNICODE_FALLBACK'
            $prepared_attrs->{$name} = $1;
        }
    }
    return $prepared_attrs;

}

sub login_data {
    my ( $sf, $db, $db_opt ) = @_;
    my $plui = App::DBBrowser::DB->new( $sf->{i}, $sf->{o} );
    my $plugin = $sf->{i}{plugin};
    my $arg = $plui->read_arguments();
    my $data = {};

    for my $item ( @$arg ) {
        my $name = $item->{name};
        my $secret = $item->{secret};
        my $field_is_required = $db_opt->{$db//''}{'field_' . $name} // $db_opt->{$plugin}{'field_' . $name} // 1; # set to "required" (1) if undefined
        if ( $field_is_required ) {
            if ( exists $sf->{i}{login_error} && $sf->{i}{login_error} ) {
                $data->{$name}{default} = undef; # if a login error occured, the user has to enter the arguments by hand
                delete $sf->{i}{login_error};
            }
            else {
                $data->{$name}{default} = $db_opt->{$db//''}{$name} // $db_opt->{$plugin}{$name} // undef;
            }
            $data->{$name}{secret}  = $secret;
        }
    }
    return $data;
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
