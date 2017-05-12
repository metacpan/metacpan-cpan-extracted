
use strict;
use warnings;

use Test::More 'no_plan';

{
    package WebApp;
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

        my $conf_driver = $self->conf_driver;
        $self->conf->init(
            file   => "t/conf-$conf_driver/03-path.conf",
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
        my $config = $self->conf->context;

        is($config->{'eddy_baby'},             'true',  $self->conf_driver . ': eddy');
        ok(!$config->{'freddy_baby'},                   $self->conf_driver . ': freddy');
        is($config->{'apps'},                  1,       $self->conf_driver . ': apps');
        is($config->{'red_apps'},              1,       $self->conf_driver . ': red_apps');
        ok(! exists $config->{'use_red_apps'},          $self->conf_driver . ': use_red_apps');
        is($config->{'colour'},                'red',   $self->conf_driver . ': colour');
        is($config->{'pi_long'},               'true',  $self->conf_driver . ': pi_long');
        ok(! exists $config->{'pi_long2'},              $self->conf_driver . ': pi_long2');
        is($config->{'one'},                   'true',  $self->conf_driver . ': one');
        return "";
    }
}

SKIP: {
    if (test_driver_prereqs('ConfigGeneral')) {
        WebApp->new(PARAMS => { conf_driver => 'ConfigGeneral' })->run;
    }
    else {
        skip "Config::General not installed", 9;
    }
}
SKIP: {
    if (test_driver_prereqs('ConfigScoped')) {
        WebApp->new(PARAMS => { conf_driver => 'ConfigScoped' })->run;
    }
    else {
        skip "Config::Scoped not installed", 9;
    }
}
SKIP: {
    if (test_driver_prereqs('XMLSimple')) {
        WebApp->new(PARAMS => { conf_driver => 'XMLSimple' })->run;
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
