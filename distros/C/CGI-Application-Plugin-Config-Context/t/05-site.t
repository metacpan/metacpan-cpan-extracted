
use strict;
use warnings;

use Test::More 'no_plan';

{
    package WebApp::Foo::Bar::Baz;
    use Test::More;

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::Context;

    sub conf_driver {
        my $self = shift;
        return $self->param('conf_driver');
    }

    sub setup {
        my $self = shift;

        $self->header_type('none');
        $self->run_modes(
            'start' => 'default',
        );

        $ENV{'SCRIPT_NAME'} = '/apps/red/users';
        $ENV{'PATH_INFO'}   = '/some/long/path/one';

        $ENV{'SITE_NAME'}   = 'fred';

        my $conf_driver = $self->conf_driver;
        $self->conf('one')->init(
            file   => "t/conf-$conf_driver/05-site.conf",
            cache_config_files => 0,
            driver => $conf_driver,
            driver_options => {
                ConfigScoped => {
                    warnings => {
                        permissions => 'off',
                    }
                }
            }
        );

        $ENV{'SITE_NAME'}   = 'unseen';

        $self->conf('two')->init(
            file   => "t/conf-$conf_driver/05-site.conf",
            cache_config_files => 0,
            driver => $conf_driver,
            driver_options => {
                ConfigScoped => {
                    warnings => {
                        permissions => 'off',
                    }
                }
            }
        );

        $ENV{'TORQUEMADA'}  = 'hat';

        $self->conf('three')->init(
            file   => "t/conf-$conf_driver/05-site.conf",
            site_var           => 'TORQUEMADA',
            site_section_name  => 'Porkpie',
            cache_config_files => 0,
            driver => $conf_driver,
            driver_options => {
                ConfigScoped => {
                    warnings => {
                        permissions => 'off',
                    }
                }
            }
        );

        $ENV{'SITE_NAME'}  = 'hat';

        $self->conf('four')->init(
            file   => "t/conf-$conf_driver/05-site.conf",
            site_section_name  => 'Porkpie',
            cache_config_files => 0,
            driver => $conf_driver,
            driver_options => {
                ConfigScoped => {
                    warnings => {
                        permissions => 'off',
                    }
                }
            }
        );
    }

    sub default {
        my $self = shift;

        my $config;

        # no match
        $config = $self->conf('one')->context;


        ok(!$config->{'caveat_emptor'},  $self->conf_driver . ': 1.caveat_emptor');
        ok(!$config->{'the_lid_man'},    $self->conf_driver . ': 1.the_lid_man');

        SKIP: {
            # XMLSimple:
            # We haven't set ForceArray to include Porkpie,
            # so it will merge this section differently

            if ($self->conf_driver eq 'XMLSimple') {
                skip "XMLSimple driver - merging behaviour", 1;
            }
            is($config->{'Porkpie'}{'hat'}{'the_lid_man'},   1, $self->conf_driver . ': 1.subsection Porkpie');
        }


        # site unseen
        $config = $self->conf('two')->context;
        ok($config->{'caveat_emptor'},   $self->conf_driver . ': 2.caveat_emptor');
        ok(!$config->{'the_lid_man'},    $self->conf_driver . ': 2.the_lid_man');

        # Porkpie hat
        $config = $self->conf('three')->context;
        ok(!$config->{'caveat_emptor'}, $self->conf_driver . ': 3.caveat_emptor');
        ok($config->{'the_lid_man'},    $self->conf_driver . ': 3.the_lid_man');

        # Porkpie hat
        $config = $self->conf('four')->context;
        ok(!$config->{'caveat_emptor'}, $self->conf_driver . ': 4.caveat_emptor');
        ok($config->{'the_lid_man'},    $self->conf_driver . ': 4.the_lid_man');


        return "";
    }
}


SKIP: {
    if (test_driver_prereqs('ConfigGeneral')) {
        WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => 'ConfigGeneral' })->run;
    }
    else {
        skip "Config::General not installed", 9;
    }
}
SKIP: {
    if (test_driver_prereqs('ConfigScoped')) {
        WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => 'ConfigScoped'  })->run;
    }
    else {
        skip "Config::Scoped not installed", 9;
    }
}
SKIP: {
    if (test_driver_prereqs('XMLSimple')) {
        WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => 'XMLSimple'     })->run;
    }
    else {
        skip "XML::Simple, XML::SAX or XML::Filter::XInclude not installed", 9;
    }
}

sub test_driver_prereqs {
    my $driver = shift;
    my $driver_module = 'Config::Context::' . $driver;
    eval "require $driver_module;";
    die $@ if $@;

    eval "require $driver_module;";
    my @required_modules = $driver_module->config_modules;

    foreach (@required_modules) {
        eval "require $_;";
        if ($@) {
            return;
        }
    }
    return 1;

}

