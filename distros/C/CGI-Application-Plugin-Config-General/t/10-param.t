
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
        $self->mode_param(
            '-path_info' => 2,
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

        is($self->conf('one')->param('winner'),          '/foo',        'winner');
        is($self->conf('one')->param('location_winner'), '/foo',        'location_winner');
        is($self->conf('one')->param('app_winner'),      'WebApp::Foo', 'app_winner');
        is($self->conf('one')->param('site_winner'),     'fred',        'site_winner');
        is($self->conf('one')->param('gordon_winner'),   'asdf',        'gordon_winner');
        is($self->conf('one')->param('none'),            0,             'none');
        is($self->conf('one')->param('tony'),            0,             'tony');
        is($self->conf('one')->param('fred'),            1,             'fred');
        is($self->conf('one')->param('foo'),             1,             'foo');
        is($self->conf('one')->param('/foo'),            1,             '/foo');
        is($self->conf('one')->param('WebApp::Foo'),     1,             'WebApp::Foo');
        is($self->conf('one')->param('WebApp::Bar'),     0,             'WebApp::Bar');
        is($self->conf('one')->param('Bar'),             1,             'Bar');

        ok(eq_array([sort $self->conf('one')->param()], [ sort qw{
                                                                none
                                                                fred
                                                                foo
                                                                /foo
                                                                tony
                                                                WebApp::Foo
                                                                WebApp::Bar
                                                                Bar
                                                                winner
                                                                site_winner
                                                                location_winner
                                                                app_winner
                                                                gordon_winner
                                                                } ]),     'keys');

        return "";
    }
}

my $webapp = WebApp::Foo::Bar::Baz->new;
$webapp->run;

