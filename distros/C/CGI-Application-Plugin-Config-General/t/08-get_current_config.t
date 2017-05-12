
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
        $ENV{'PATH_INFO'} = '/foo/bar/baz/bam/boom';
        $self->mode_param(
            '-path_info' => 2,
        );

        $self->conf->init(
            -ConfigFile => 't/conf/02-init1.conf',
        );
        $self->conf('test')->init(
            -ConfigFile => 't/conf/02-init2.conf',
            -Options => {
                -LowerCaseNames => 1,
            },
        );

    }

    sub default {
        my $self = shift;


        # Standard methods, copied from test 01-init
        my $config1 = $self->conf->getall;

        is($config1->{'some_section'}{'a'}{'val1'}, 'foo', 'some_section a/val1');
        is($config1->{'some_section'}{'a'}{'val2'}, 'bar', 'some_section a/val1');
        ok(!exists $config1->{'some_section'}{'b'}, 'some_section b');
        is($config1->{'some_SECTion'}{'b'}{'VAL3'}, 'foo', 'some_section b/val3');
        is($config1->{'some_SECTion'}{'b'}{'val4'}, 'bar', 'some_section b/val4');


        is(ref $self->conf->obj, 'Config::General::Match', 'obj ref');
        my %config1 = $self->conf->obj->getall;

        is($config1{'some_section'}{'a'}{'val1'}, 'foo', 'some_section a/val1');
        is($config1{'some_section'}{'a'}{'val2'}, 'bar', 'some_section a/val1');
        ok(!exists $config1{'some_section'}{'b'}, 'some_section b');
        is($config1{'some_SECTion'}{'b'}{'VAL3'}, 'foo', 'some_section b/val3');
        is($config1{'some_SECTion'}{'b'}{'val4'}, 'bar', 'some_section b/val4');

        my %config2 = $self->conf('test')->getall;

        is($config2{'some_options'}{'C'}{'vala'}, 'baz', '[test] some_options b/val1');
        is($config2{'some_options'}{'C'}{'valb'}, 'boom', '[test] some_options b/val1');



        # using get_current_config class methods

        $config1 = CGI::Application::Plugin::Config::General->get_current_config;

        is($config1->{'some_section'}{'a'}{'val1'}, 'foo', '[cc]some_section a/val1');
        is($config1->{'some_section'}{'a'}{'val2'}, 'bar', '[cc]some_section a/val1');
        ok(!exists $config1->{'some_section'}{'b'},        '[cc]some_section b');
        is($config1->{'some_SECTion'}{'b'}{'VAL3'}, 'foo', '[cc]some_section b/val3');
        is($config1->{'some_SECTion'}{'b'}{'val4'}, 'bar', '[cc]some_section b/val4');


        %config1 = CGI::Application::Plugin::Config::General->get_current_config;

        is($config1{'some_section'}{'a'}{'val1'}, 'foo', '[cc]some_section a/val1');
        is($config1{'some_section'}{'a'}{'val2'}, 'bar', '[cc]some_section a/val1');
        ok(!exists $config1{'some_section'}{'b'},        '[cc]some_section b');
        is($config1{'some_SECTion'}{'b'}{'VAL3'}, 'foo', '[cc]some_section b/val3');
        is($config1{'some_SECTion'}{'b'}{'val4'}, 'bar', '[cc]some_section b/val4');

        my $config2 = CGI::Application::Plugin::Config::General->get_current_config('test');

        is($config2->{'some_options'}{'C'}{'vala'}, 'baz',  '[cc:test]some_options b/val1');
        is($config2->{'some_options'}{'C'}{'valb'}, 'boom', '[cc:test]some_options b/val1');



        return "";
    }
}

my $webapp = WebApp->new;
$webapp->run;

SKIP: {
    skip "Current CGI::Application doesn't support callbacks", 2 unless $webapp->can('add_callback');
    my $config1 = CGI::Application::Plugin::Config::General->get_current_config;

    ok((ref $config1 eq 'HASH'),     'default config empty at end of request - hashref returned');
    ok((scalar keys %$config1) == 0, 'default config empty at end of request - hashref has no keys');
}
