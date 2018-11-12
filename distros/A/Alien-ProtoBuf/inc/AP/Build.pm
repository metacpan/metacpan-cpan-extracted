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

sub ACTION_alien_code {
    my $self = shift;
    $self->SUPER::ACTION_alien_code();
    my $system_provides = scalar $self->config_data('system_provides');

    my $version = $self->alien_check_installed_version;
    my ($major, $minor) = split /\./, $version;
    if ($major > 3 || ($major == 3 && $minor >= 6)) {
        if (!ExtUtils::CppGuess->new->is_msvc) {
            $system_provides->{'C++flags'} = "-std=c++11";
        }
    }
}

1;
