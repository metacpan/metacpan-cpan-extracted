
use strict;
use warnings;


use Test::More;

eval { require Config::General; };

if ($@) {
    plan 'skip_all' => "Config::General not installed"
}
else {
    plan 'no_plan';
}

{
    package Some::Other::Package;
    use Test::More;

    sub do_stuff {
        # using get_current_* class methods

        my $config1 = CGI::Application::Plugin::Config::Context->get_current_context;

        is($config1->{'some_section'}{'a'}{'val1'}, 'foo', '[cc]some_section a/val1');
        is($config1->{'some_section'}{'a'}{'val2'}, 'bar', '[cc]some_section a/val1');
        ok(!exists $config1->{'some_section'}{'b'},        '[cc]some_section b');
        is($config1->{'some_SECTion'}{'b'}{'VAL3'}, 'foo', '[cc]some_section b/val3');
        is($config1->{'some_SECTion'}{'b'}{'val4'}, 'bar', '[cc]some_section b/val4');


        my %config1 = CGI::Application::Plugin::Config::Context->get_current_context;

        is($config1{'some_section'}{'a'}{'val1'}, 'foo', '[cc]some_section a/val1');
        is($config1{'some_section'}{'a'}{'val2'}, 'bar', '[cc]some_section a/val1');
        ok(!exists $config1{'some_section'}{'b'},        '[cc]some_section b');
        is($config1{'some_SECTion'}{'b'}{'VAL3'}, 'foo', '[cc]some_section b/val3');
        is($config1{'some_SECTion'}{'b'}{'val4'}, 'bar', '[cc]some_section b/val4');

        my %raw_config1 = CGI::Application::Plugin::Config::Context->get_current_raw_config;

        is($raw_config1{'some_section'}{'a'}{'val1'}, 'foo', '[cc]some_section a/val1');
        is($raw_config1{'some_section'}{'a'}{'val2'}, 'bar', '[cc]some_section a/val1');
        ok(!exists $raw_config1{'some_section'}{'b'},        '[cc]some_section b');
        is($raw_config1{'some_SECTion'}{'b'}{'VAL3'}, 'foo', '[cc]some_section b/val3');
        is($raw_config1{'some_SECTion'}{'b'}{'val4'}, 'bar', '[cc]some_section b/val4');


        my $config2 = CGI::Application::Plugin::Config::Context->get_current_context('test');

        is($config2->{'some_options'}{'C'}{'vala'}, 'baz',  '[cc:test]some_options b/val1');
        is($config2->{'some_options'}{'C'}{'valb'}, 'boom', '[cc:test]some_options b/val1');


    }
}

{
    package WebApp;
    use Test::More;

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::Context;

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
            file        => 't/conf-ConfigGeneral/02-init1.conf',
        );
        $self->conf('test')->init(
            file             => 't/conf-ConfigGeneral/02-init2.conf',
            lower_case_names => 1,
        );

    }

    sub default {
        my $self = shift;


        # Standard methods, copied from test 01-init
        my $config1 = $self->conf->context;

        is($config1->{'some_section'}{'a'}{'val1'}, 'foo', 'some_section a/val1');
        is($config1->{'some_section'}{'a'}{'val2'}, 'bar', 'some_section a/val1');
        ok(!exists $config1->{'some_section'}{'b'}, 'some_section b');
        is($config1->{'some_SECTion'}{'b'}{'VAL3'}, 'foo', 'some_section b/val3');
        is($config1->{'some_SECTion'}{'b'}{'val4'}, 'bar', 'some_section b/val4');



        my %config2 = $self->conf('test')->context;

        is($config2{'some_options'}{'C'}{'vala'}, 'baz', '[test] some_options b/val1');
        is($config2{'some_options'}{'C'}{'valb'}, 'boom', '[test] some_options b/val1');

        Some::Other::Package::do_stuff();

        return "";
    }
}

my $webapp = WebApp->new;
$webapp->run;

