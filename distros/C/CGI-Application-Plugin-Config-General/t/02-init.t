
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

        is($config2{'some_options'}{'C'}{'vala'}, 'baz', 'some_options b/val1');
        is($config2{'some_options'}{'C'}{'valb'}, 'boom', 'some_options b/val1');
        return "";
    }
}

my $webapp = WebApp->new;
$webapp->run;
