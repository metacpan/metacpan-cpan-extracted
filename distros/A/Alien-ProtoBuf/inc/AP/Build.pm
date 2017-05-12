package AP::Build;

use strict;
use warnings;
use parent 'Alien::Base::ModuleBuild';

use ExtUtils::CBuilder;
use ExtUtils::CppGuess;

my @try_flags = (
    {
        linker_flags => '-lprotobuf',
    },
);

sub new {
    my $class = shift;
    my $flags = $class->_find_installed_version;
    my $self = $class->SUPER::new(
        @_,
        alien_name            => 'protobuf',
        alien_provides_cflags => $flags->{compiler_flags},
        alien_provides_libs   => $flags->{linker_flags},
    );

    if (!$self->SUPER::alien_check_installed_version &&
            !$self->alien_check_installed_version) {
        # this should get us an "NA"
        warn "Could not find an installed protobuf library";
        exit 0;
    }

    return $self;
}

sub alien_check_installed_version {
    my($self) = @_;

    return $self->SUPER::alien_check_installed_version
        unless $self->alien_provides_libs;

    my $builder = ExtUtils::CBuilder->new(quiet => 1);

    die "C++ compiler not found"
        unless $builder->have_cplusplus;

    my %cxx_flags = ExtUtils::CppGuess->new->module_build_options;
    my ($version, $flags) = _check_flags(
        $builder, \%cxx_flags,
        compiler_flags  => $self->alien_provides_cflags,
        linker_flags    => $self->alien_provides_libs,
    );

    return unless defined $version;
    return $version;
}

sub _find_installed_version {
    my($class) = @_;
    my $builder = ExtUtils::CBuilder->new(quiet => 1);

    die "C++ compiler not found"
        unless $builder->have_cplusplus;

    my %cxx_flags = ExtUtils::CppGuess->new->module_build_options;
    my ($version, $flags);
    for my $try_flags (@try_flags) {
        eval {
            ($version, $flags) = _check_flags(
                $builder, \%cxx_flags, %$try_flags,
            );
        };
        last if $version;
    }

    return unless defined $version;
    return $flags;
}

sub _check_flags {
    my ($builder, $cxx_flags, %flags) = @_;
    my $object = $builder->object_file('inc/AP/test.cpp');
    my $exe = $builder->exe_file($object);

    $builder->compile(
        source               => 'inc/AP/check_protobuf.cpp',
        object_file          => $object,
        extra_compiler_flags =>
            join(' ',
                 $cxx_flags->{extra_compiler_flags} // '',
                 $flags{compiler_flags} // ''),
    );
    $builder->link_executable(
        objects            => [$object],
        extra_linker_flags =>
            join(' ',
                 $cxx_flags->{extra_linker_flags} // '',
                 $flags{linker_flags} // ''),
    );

    my $version = qx($exe);
    $version = join '.', map $_ + 0, $version =~ /^(\d+)(\d{3})(\d{3})$/
        if $version;

    return ($version, \%flags);
}

1;
