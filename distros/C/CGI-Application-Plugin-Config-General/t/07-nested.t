
use strict;
use warnings;

use Test::More 'no_plan';

my $Config;

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

        $self->conf->init(
            -ConfigFile       => 't/conf/07-nested.conf',
            -CacheConfigFiles => 0,
        );

        $Config = $self->conf->getall;


    }

    sub default {
        return "";
    }
}


#1 site=fred; loc=/tony/baz
$ENV{'SCRIPT_NAME'} = '/tony';
$ENV{'PATH_INFO'}   = '/baz';
$ENV{'SITE_NAME'}   = 'fred';

WebApp::Foo::Bar::Baz->new->run;

is($Config->{'foo'},             1,        '1.foo');
is($Config->{'gordon'},          0,        '1.gordon');
is($Config->{'/tony'},           1,        '1./tony');
is($Config->{'fred'},            1,        '1.fred');
is($Config->{'simon'},           0,        '1.simon');
is($Config->{'winner'},          'foo',    '1.winner');  # not longest, but most deeply nested
is($Config->{'location_winner'}, '/tony',  '1.location_winner');
is($Config->{'site_winner'},     'fred',   '1.site_winner');
is($Config->{'app_winner'},      'foo',    '1.app_winner');


#3 site=wubba; loc=/tony/simon
$ENV{'SCRIPT_NAME'} = '/tony';
$ENV{'PATH_INFO'}   = '/simon';
$ENV{'SITE_NAME'}   = 'wubba';

WebApp::Foo::Bar::Baz->new->run;

is($Config->{'foo'},             0,        '2.foo');
is($Config->{'gordon'},          0,        '2.gordon');
is($Config->{'/tony'},           1,        '2./tony');
is($Config->{'fred'},            0,        '2.fred');
is($Config->{'simon'},           0,        '2.simon');
is($Config->{'winner'},          '/tony',  '2.winner');
is($Config->{'location_winner'}, '/tony',  '2.location_winner');
is($Config->{'site_winner'},     'asdf',   '2.site_winner');
is($Config->{'app_winner'},      'asdf',   '2.app_winner');


#4 site=gordon; loc=/baker/fred
$ENV{'SCRIPT_NAME'} = '/baker';
$ENV{'PATH_INFO'}   = '/fred';
$ENV{'SITE_NAME'}   = 'gordon';

WebApp::Foo::Bar::Baz->new->run;

is($Config->{'foo'},             0,        '3.foo');
is($Config->{'gordon'},          0,        '3.gordon');
is($Config->{'/tony'},           0,        '3./tony');
is($Config->{'fred'},            0,        '3.fred');
is($Config->{'simon'},           0,        '3.simon');
is($Config->{'winner'},          'asdf',   '3.winner');
is($Config->{'location_winner'}, 'asdf',   '3.location_winner');
is($Config->{'site_winner'},     'asdf',   '3.site_winner');
is($Config->{'app_winner'},      'asdf',   '3.app_winner');


#5 site=gordon; loc=/tony
$ENV{'SCRIPT_NAME'} = '/tony';
$ENV{'PATH_INFO'}   = '';
$ENV{'SITE_NAME'}   = 'gordon';

WebApp::Foo::Bar::Baz->new->run;

is($Config->{'foo'},             0,        '4.foo');
is($Config->{'gordon'},          1,        '4.gordon');
is($Config->{'/tony'},           1,        '4./tony');
is($Config->{'fred'},            0,        '4.fred');
is($Config->{'simon'},           0,        '4.simon');
is($Config->{'winner'},          'gordon', '4.winner');  # not longest or highest priority, but most deeply nested
is($Config->{'location_winner'}, '/tony',  '4.location_winner');
is($Config->{'site_winner'},     'gordon', '4.site_winner');
is($Config->{'app_winner'},      'asdf',   '4.app_winner');

