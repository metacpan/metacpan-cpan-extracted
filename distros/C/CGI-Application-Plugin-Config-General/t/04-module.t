
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

        $ENV{'SCRIPT_NAME'} = '/apps/red/users';
        $ENV{'PATH_INFO'}   = '/some/long/path/one';

        $self->conf->init(
            -ConfigFile => 't/conf/04-module.conf',
        );
    }

    sub default {
        my $self = shift;
        my $config = $self->conf->getall;

        is($config->{'is_plain_foo'},  0, 'is_plain_foo');
        is($config->{'is_webapp_foo'}, 1, 'is_webapp_foo');
        is($config->{'is_webapp_fo'},  0, 'is_webapp_fo');
        is($config->{'has_webapp_fo'}, 1, 'has_webapp_fo');
        is($config->{'has_baz'},       1, 'has_baz');
        is($config->{'ends_with_bar'}, 0, 'ends_with_bar');
        is($config->{'some_location'}, 1, 'some_location');
        is($config->{'long_location'}, 0, 'long_location');

        return "";
    }
}

my $webapp = WebApp::Foo::Bar::Baz->new;
$webapp->run;


