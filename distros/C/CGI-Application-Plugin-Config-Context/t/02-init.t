
use strict;
use warnings;

use Test::More 'no_plan';

{
    package WebApp;
    use Test::More;

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::Context;

    sub conf_driver {
        my $self = shift;
        return $self->param('conf_driver');
    }

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

        if ($self->conf_driver) {
            my $conf_driver = $self->conf_driver;
            $self->conf->init(
                file   => "t/conf-$conf_driver/02-init1.conf",
                driver => $conf_driver,
                driver_options => {
                    ConfigScoped => {
                        warnings => {
                            permissions => 'off',
                        }
                    }
                }
            );
            $self->conf('test')->init(
                file             => "t/conf-$conf_driver/02-init2.conf",
                lower_case_names => 1,
                driver           => $conf_driver,
                driver_options => {
                    ConfigScoped => {
                        warnings => {
                            permissions => 'off',
                        }
                    }
                }
            );
        }
        else {
            $self->conf->init(
                file        => 't/conf-ConfigGeneral/02-init1.conf',
            );
            $self->conf('test')->init(
                file             => 't/conf-ConfigGeneral/02-init2.conf',
                lower_case_names => 1,
            );
        }

    }

    sub default {
        my $self = shift;
        my $config1 = $self->conf->context;

        my $driver_name = $self->conf_driver || 'ConfigGeneral (by default)';

        is($config1->{'some_section'}{'a'}{'val1'}, 'foo', $driver_name . ': some_section a/val1');
        is($config1->{'some_section'}{'a'}{'val2'}, 'bar', $driver_name . ': some_section a/val1');
        ok(!exists $config1->{'some_section'}{'b'},        $driver_name . ': some_section b');

        is($config1->{'some_SECTion'}{'b'}{'VAL3'}, 'foo', $driver_name . ': some_section b/val3');
        is($config1->{'some_SECTion'}{'b'}{'val4'}, 'bar', $driver_name . ': some_section b/val4');

        my %config2 = $self->conf('test')->context;

        # Config::General and Config::Scoped handle lower case names differently:
        # Config::General: <section FOO>...</section>   => {section}{FOO}
        # Config::Scoped:  section FOO { ... }          => {section}{foo}

        my $section_key = 'C';
        $section_key = 'c' if $self->conf_driver and $self->conf_driver eq 'ConfigScoped';

        is($config2{'some_options'}{$section_key}{'vala'}, 'baz',  $driver_name . ': some_options b/val1');
        is($config2{'some_options'}{$section_key}{'valb'}, 'boom', $driver_name . ': some_options b/val1');
        return "";
    }
}


SKIP: {
    if (test_driver_prereqs('ConfigGeneral')) {
        WebApp->new->run;
        WebApp->new(PARAMS => { conf_driver => 'ConfigGeneral' })->run;
    }
    else {
        skip "Config::General not installed", 42;
    }
}
SKIP: {
    if (test_driver_prereqs('ConfigScoped')) {
        WebApp->new(PARAMS => { conf_driver => 'ConfigScoped'  })->run;
    }
    else {
        skip "Config::Scoped not installed", 21;
    }
}

# skip XMLSimple - it doesn't support lower_case_names

sub test_driver_prereqs {
    my $driver = shift;
    my $driver_module = 'Config::Context::' . $driver;
    eval "require $driver_module;";
    die $@ if $@;

    eval "require $driver_module;";
    my @required_modules = $driver_module->config_modules;

    foreach (@required_modules) {
        eval "require $_;";
        if ($@) {
            return;
        }
    }
    return 1;

}
