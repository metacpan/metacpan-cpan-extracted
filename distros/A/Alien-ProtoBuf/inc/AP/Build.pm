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

    if (!$self->alien_check_installed_version) {
        # this should get us an "NA"
        warn "Could not find an installed protobuf library";
        exit 0;
    }

    return $self;
}

sub alien_provides_cflags {
    my $self = shift;
    my $cflags = $self->SUPER::alien_provides_cflags || '';
    if ($^O eq 'freebsd' && $cflags !~ m{/usr/local/include}) {
        $cflags = "$cflags -I/usr/local/include";
    }
    return $cflags;
}

1;
