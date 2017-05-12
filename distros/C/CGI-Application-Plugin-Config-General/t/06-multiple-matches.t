
use strict;
use warnings;

use Test::More 'no_plan';

{
    package WebApp::Foo::Bar::Baz;
    use Test::More;

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::General;

    sub setup {
        my $self = shift;

        $self->header_type('none');
        $self->run_modes(
            'start' => 'default',
        );

        $ENV{'SCRIPT_NAME'} = '/foo/bar';
        $ENV{'PATH_INFO'}   = '/baz';

        $ENV{'SITE_NAME'}   = 'fred';

        $self->conf('one')->init(
            -ConfigFile       => 't/conf/06-multiple-matches.conf',
            -CacheConfigFiles => 0,
        );

    }

    sub default {
        my $self = shift;

        my $config;

        $config = $self->conf('one')->getall;
        is($config->{'winner'},          '/foo',        'winner');
        is($config->{'location_winner'}, '/foo',        'location_winner');
        is($config->{'app_winner'},      'WebApp::Foo', 'app_winner');
        is($config->{'site_winner'},     'fred',        'site_winner');
        is($config->{'gordon_winner'},   'asdf',        'gordon_winner');
        is($config->{'none'},            0,             'none');
        is($config->{'tony'},            0,             'tony');
        is($config->{'fred'},            1,             'fred');
        is($config->{'foo'},             1,             'foo');
        is($config->{'/foo'},            1,             '/foo');
        is($config->{'WebApp::Foo'},     1,             'WebApp::Foo');
        is($config->{'WebApp::Bar'},     0,             'WebApp::Bar');
        is($config->{'Bar'},             1,             'Bar');

        return "";
    }
}

my $webapp = WebApp::Foo::Bar::Baz->new;
$webapp->run;



