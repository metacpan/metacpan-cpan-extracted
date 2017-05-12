
use strict;
use warnings;

use Test::More 'no_plan';

my $Config;

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

        my $conf_driver = $self->conf_driver;
        $self->conf->init(
            file   => "t/conf-$conf_driver/07-nested.conf",
            driver => $conf_driver,
            driver_options => {
                ConfigScoped => {
                    warnings => {
                        permissions => 'off',
                    }
                }
            }
        );
        $Config = $self->conf->context;
    }
    sub default {
        '';
    }
}

sub run_the_tests {
    my $conf_driver = shift;

    my $config;

    $ENV{'SCRIPT_NAME'} = '/tony';
    $ENV{'PATH_INFO'}   = '/baz';
    $ENV{'SITE_NAME'}   = 'fred';

    WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => $conf_driver })->run;

    # site=fred; loc=/tony/baz
    is($Config->{'foo'},             1,        $conf_driver . ': 1.foo');
    ok(!$Config->{'gordon'},                   $conf_driver . ': 1.gordon');
    is($Config->{'slash_tony'},      1,        $conf_driver . ': 1./tony');
    is($Config->{'fred'},            1,        $conf_driver . ': 1.fred');
    ok(!$Config->{'simon'},                    $conf_driver . ': 1.simon');
    is($Config->{'winner'},          'foo',    $conf_driver . ': 1.winner');  # not longest, but most deeply nested
    is($Config->{'location_winner'}, '/tony',  $conf_driver . ': 1.location_winner');
    is($Config->{'site_winner'},     'fred',   $conf_driver . ': 1.site_winner');
    is($Config->{'app_winner'},      'foo',    $conf_driver . ': 1.app_winner');


    $ENV{'SCRIPT_NAME'} = '/tony';
    $ENV{'PATH_INFO'}   = '/simon';
    $ENV{'SITE_NAME'}   = 'wubba';

    WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => $conf_driver })->run;

    # site=wubba; loc=/tony/simon
    ok(!$Config->{'foo'},                      $conf_driver . ': 2.foo');
    ok(!$Config->{'gordon'},                   $conf_driver . ': 2.gordon');
    is($Config->{'slash_tony'},      1,        $conf_driver . ': 2./tony');
    ok(!$Config->{'fred'},                     $conf_driver . ': 2.fred');
    ok(!$Config->{'simon'},                    $conf_driver . ': 2.simon');
    is($Config->{'winner'},          '/tony',  $conf_driver . ': 2.winner');
    is($Config->{'location_winner'}, '/tony',  $conf_driver . ': 2.location_winner');
    ok(!$Config->{'site_winner'},              $conf_driver . ': 2.site_winner');
    ok(!$Config->{'app_winner'},               $conf_driver . ': 2.app_winner');

    $ENV{'SCRIPT_NAME'} = '/baker';
    $ENV{'PATH_INFO'}   = '/fred';
    $ENV{'SITE_NAME'}   = 'gordon';

    WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => $conf_driver })->run;

    # site=gordon; loc=/baker/fred
    ok(!$Config->{'foo'},                      $conf_driver . ': 3.foo');
    ok(!$Config->{'gordon'},                   $conf_driver . ': 3.gordon');
    ok(!$Config->{'slash_tony'},               $conf_driver . ': 3./tony');
    ok(!$Config->{'fred'},                     $conf_driver . ': 3.fred');
    ok(!$Config->{'simon'},                    $conf_driver . ': 3.simon');
    ok(!$Config->{'winner'},                   $conf_driver . ': 3.winner');
    ok(!$Config->{'location_winner'},          $conf_driver . ': 3.location_winner');
    ok(!$Config->{'site_winner'},              $conf_driver . ': 3.site_winner');
    ok(!$Config->{'app_winner'},               $conf_driver . ': 3.app_winner');

    $ENV{'SCRIPT_NAME'} = '/tony';
    $ENV{'PATH_INFO'}   = '';
    $ENV{'SITE_NAME'}   = 'gordon';

    WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => $conf_driver })->run;

    # site=gordon; loc=/tony
    ok(!$Config->{'foo'},                      $conf_driver . ': 4.foo');
    is($Config->{'gordon'},          1,        $conf_driver . ': 4.gordon');
    is($Config->{'slash_tony'},      1,        $conf_driver . ': 4./tony');
    ok(!$Config->{'fred'},                     $conf_driver . ': 4.fred');
    ok(!$Config->{'simon'},                    $conf_driver . ': 4.simon');
    is($Config->{'winner'},          'gordon', $conf_driver . ': 4.winner');  # not longest or highest priority, but most deeply nested
    is($Config->{'location_winner'}, '/tony',  $conf_driver . ': 4.location_winner');
    is($Config->{'site_winner'},     'gordon', $conf_driver . ': 4.site_winner');
    ok(!$Config->{'app_winner'},               $conf_driver . ': 4.app_winner');

}


SKIP: {
    if (test_driver_prereqs('ConfigGeneral')) {
        run_the_tests('ConfigGeneral');
    }
    else {
        skip "Config::General not installed", 36;
    }
}
SKIP: {
    if (test_driver_prereqs('ConfigScoped')) {
        run_the_tests('ConfigScoped');
    }
    else {
        skip "Config::Scoped not installed", 36;
    }
}
SKIP: {
    if (test_driver_prereqs('XMLSimple')) {
        run_the_tests('XMLSimple');
    }
    else {
        skip "XML::Simple, XML::SAX or XML::Filter::XInclude not installed", 36;
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

