use strict;
use warnings;
use Module::Build;

my %options = (
    profile => 0,
    cc => 'gcc',
    debug => 1,
);

my $linker_flags = $options{cc} eq 'gcc'
    ? q{ }
    : q{ };
my $compiler_flags =  q{ -I. -O2 -finline-functions -funswitch-loops};

$compiler_flags .= ($options{debug}) ? q{ -g } : q{};

my $builder = Module::Build->new(
    module_name             => 'Class::Std::Fast_XS',
    dist_version            => 0.3,
    license                 => 'perl',
    dist_author             => q{Martin Kutter - MKUTTER@cpan.org},
    create_makefile_pl      => 'small',
    extra_linker_flags      => $linker_flags,
    extra_compiler_flags    => $compiler_flags,
    requires                => {
        'perl'                    => q(5.8.0),
        'Class::Std::Fast'        => q(0.0.8),
    }
);

$builder->create_build_script();
