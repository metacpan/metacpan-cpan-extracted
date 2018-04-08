use strict;
use warnings;
use Cwd;
use Module::Build;
use Module::CPANfile;

my $cwd = Cwd::cwd();
my $file = Module::CPANfile->load('cpanfile');
my $prereq = $file->prereq_specs;

my %args = (
    module_name          => 'App::Koyomi',
    license              => 'perl',
    dist_author          => 'IKEDA Kiyoshi <progrhyme@gmail.com>',
    dist_version_from    => 'lib/App/Koyomi.pm',
    script_files         => [glob('script/*'), glob('bin/*')],
    add_to_cleanup       => ['App-Koyomi-*'],
    test_files           => 't/',
    recursive_test_files => 1,
    tap_harness_args     => {
        lib => ["$cwd/lib", "$cwd/t/lib"],
    },
    configure_requires   => $prereq->{configure}->{requires},
    build_requires       => {
        %{$prereq->{build}->{requires}},
        %{$prereq->{test}->{requires}},
    },
    requires             => $prereq->{runtime}->{requires},
);

my $builder = Module::Build->subclass(
    class => 'KoyomiBuilder',
    code  => q{
        sub ACTION_test_libs {
            my $self = shift;
            local @INC = @INC;
            unshift @INC, 't/lib';
            $self->SUPER::ACTION_test(@_);
        }
    },
)->new(%args);

$builder->create_build_script();
