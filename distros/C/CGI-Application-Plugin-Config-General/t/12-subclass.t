
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
            -ConfigFile => 't/conf/12-module.conf',
        );
    }

    sub default {
        my $self = shift;
        my $config = $self->conf->getall;

        is($config->{'is_foo'},        1, 'is_foo');

        return "";
    }
}


{
    package WebApp::Foo;
    our @ISA = qw(WebApp);

}


my $webapp = WebApp::Foo->new;
$webapp->run;


