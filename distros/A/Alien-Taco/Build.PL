#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass(
    class => 'TacoBuilder',
    code => q{
        use TAP::Harness;
        use File::Spec;
        sub ACTION_tiperl {
            shift->run_taco_tests(<ti-perl/*.t>);
        }
        sub ACTION_tipython {
            shift->run_taco_tests(<ti-python/*.t>);
        }
        sub run_taco_tests {
            my $self = shift;
            $self->depends_on('code');
            my $harness = new TAP::Harness({
                lib => [File::Spec->catdir(
                $self->{'properties'}->{'base_dir'},
                $self->blib(), 'lib'), @INC],
            });
            $harness->runtests(sort @_);

        }
    },
);

my $build = $class->new(
    module_name => 'Alien::Taco',
    dist_abstract => 'Taco Perl module',
    dist_author => 'Graham Bell <graham.s.bell@gmail.com>',
    license => 'gpl',
    requires => {
        'JSON' => 0,
    },
    build_requires => {
        'DateTime' => 0,
        'IO::String' => 0,
        'Test::More' => 0,
    },
);

$build->create_build_script();
