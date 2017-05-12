
use strict;
use warnings;

use Test::More 'no_plan';

{
    package WebApp;
    use Test::More;

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::General;

    sub setup {
        my $self = shift;

        $self->header_type('none');
        $self->run_modes(
            'start' => 'default',
        );

        $ENV{'SCRIPT_NAME'} = '/apps/red/users';
        $ENV{'PATH_INFO'}   = '/some/long/path/one';

        $self->conf->init(
            -ConfigFile => 't/conf/03-path.conf',
        );
    }

    sub default {
        my $self = shift;
        my $config = $self->conf->getall;

        is($config->{'eddy_baby'},             'true',  'eddy');
        is($config->{'freddy_baby'},           'false', 'freddy');
        is($config->{'apps'},                  1,       'apps');
        is($config->{'red_apps'},              1,       'red_apps');
        ok(! exists $config->{'use_red_apps'},          'use_red_apps');
        is($config->{'colour'},                'red',   'colour');
        is($config->{'pi_long'},               'true',  'pi_long');
        ok(! exists $config->{'pi_long2'},              'pi_long2');
        is($config->{'one'},                   'true',  'one');
        return "";
    }
}

my $webapp = WebApp->new;
$webapp->run;

