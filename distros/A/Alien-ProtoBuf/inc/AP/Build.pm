package AP::Build;

use strict;
use warnings;
use parent 'Alien::Base::ModuleBuild';

use ExtUtils::CBuilder;
use ExtUtils::CppGuess;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(
        @_,
        alien_name            => 'protobuf',
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

1;
