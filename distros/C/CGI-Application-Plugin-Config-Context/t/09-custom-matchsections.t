
use strict;
use warnings;

use Test::More 'no_plan';

{
    package WebApp::Pear;
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
        $self->mode_param(
            '-path_info' => 2,
        );

        $ENV{'SITE_NAME'} = 'rhonda';
        $ENV{'SCRIPT_NAME'} = '/foo/bar.cgi';

        my $conf_driver = $self->conf_driver;
        $self->conf->init(
            file   => "t/conf-$conf_driver/09-custom-matchsections.conf",
            driver => $conf_driver,
            match_sections => [
                {
                    name         => 'fruit',
                    section_type => 'module',
                    match_type   => 'substring',
                }
            ],
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

        my $config = $self->conf->context;
        ok(!$config->{'apple'},        $self->conf_driver . ': apple');
        is($config->{'pear'},    1,    $self->conf_driver . ': pear');
        ok(!$config->{'rhonda'},       $self->conf_driver . ': rhonda');
        ok(!$config->{'foo'},          $self->conf_driver . ': foo');

        return "";
    }
}




SKIP: {
    if (test_driver_prereqs('ConfigGeneral')) {
        WebApp::Pear->new(PARAMS => { conf_driver => 'ConfigGeneral' })->run;
    }
    else {
        skip "Config::General not installed", 4;
    }
}
SKIP: {
    if (test_driver_prereqs('ConfigScoped')) {
        WebApp::Pear->new(PARAMS => { conf_driver => 'ConfigScoped'  })->run;
    }
    else {
        skip "Config::Scoped not installed", 4;
    }
}
SKIP: {
    if (test_driver_prereqs('XMLSimple')) {
        WebApp::Pear->new(PARAMS => { conf_driver => 'XMLSimple'     })->run;
    }
    else {
        skip "XML::Simple, XML::SAX or XML::Filter::XInclude not installed", 4;
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


