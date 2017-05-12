
use strict;
use warnings;

use Test::More 'no_plan';

my $Package = 'CGI::Application::Plugin::Config::General';

{
    package WebApp;
    use Test::More;

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::General;

    sub cgiapp_init {
        my $self = shift;

        my $conf1 = $self->conf;
        my $conf2 = $self->conf('named');
        my $conf3 = $self->conf;
        my $conf4 = $self->conf('named');

        is(ref $conf1, $Package, 'conf1 object created');
        is(ref $conf2, $Package, 'conf2 object created');
        is(ref $conf3, $Package, 'conf3 object created');
        is(ref $conf4, $Package, 'conf4 object created');

        is("$conf1", "$conf3", "Unnamed configs are same object");
        is("$conf2", "$conf4", "Named configs are same object");
        isnt("$conf1", "$conf2", "Named and and Unnamed configs are different objects");

    }

}

my $webapp = WebApp->new;
