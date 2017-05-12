
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
        $self->mode_param(
            '-path_info' => 2,
        );

        $ENV{'SCRIPT_NAME'} = '/foo/bar';
        $ENV{'PATH_INFO'}   = '/baz';

        $ENV{'SITE_NAME'}   = 'fred';

        my $conf_driver = $self->conf_driver;
        $self->conf('one')->init(
            file   => "t/conf-$conf_driver/06-multiple-matches.conf",
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

        is($self->conf('one')->param('winner'),          '/foo',        $self->conf_driver . ': winner');
        is($self->conf('one')->param('location_winner'), '/foo',        $self->conf_driver . ': location_winner');
        is($self->conf('one')->param('app_winner'),      'WebApp::Foo', $self->conf_driver . ': app_winner');
        is($self->conf('one')->param('site_winner'),     'fred',        $self->conf_driver . ': site_winner');
        ok(!$self->conf('one')->param('gordon_winner'),                 $self->conf_driver . ': gordon_winner');
        ok(!$self->conf('one')->param('none'),                          $self->conf_driver . ': none');
        ok(!$self->conf('one')->param('tony'),                          $self->conf_driver . ': tony');
        is($self->conf('one')->param('fred'),            1,             $self->conf_driver . ': fred');
        is($self->conf('one')->param('foo'),             1,             $self->conf_driver . ': foo');
        is($self->conf('one')->param('slash_foo'),       1,             $self->conf_driver . ': /foo');
        is($self->conf('one')->param('WebApp_Foo'),      1,             $self->conf_driver . ': WebApp::Foo');
        ok(!$self->conf('one')->param('WebApp_Bar'),                    $self->conf_driver . ': WebApp::Bar');
        is($self->conf('one')->param('Bar'),             1,             $self->conf_driver . ': Bar');

        ok(eq_array([sort $self->conf('one')->param()], [ sort qw{
                                                                  Bar
                                                                  slash_foo
                                                                  winner
                                                                  WebApp_Foo
                                                                  site_winner
                                                                  location_winner
                                                                  foo
                                                                  app_winner
                                                                  fred
                                                                } ]),     $self->conf_driver . ': keys');

        return "";
    }
}


SKIP: {
    if (test_driver_prereqs('ConfigGeneral')) {
        WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => 'ConfigGeneral' })->run;
    }
    else {
        skip "Config::General not installed", 14;
    }
}
SKIP: {
    if (test_driver_prereqs('ConfigScoped')) {
        WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => 'ConfigScoped'  })->run;
    }
    else {
        skip "Config::Scoped not installed", 14;
    }
}
SKIP: {
    if (test_driver_prereqs('XMLSimple')) {
        WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => 'XMLSimple'     })->run;
    }
    else {
        skip "XML::Simple, XML::SAX or XML::Filter::XInclude not installed", 14;
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


