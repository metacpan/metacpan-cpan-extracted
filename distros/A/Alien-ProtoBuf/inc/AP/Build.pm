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

    return if ExtUtils::CppGuess->new->is_msvc;

    my $system_provides = scalar $self->config_data('system_provides');
    my $version = $self->alien_check_installed_version;
    my ($major, $minor) = split /\./, $version;

    # C++11 is required by Prootbuf, while the higher C++ standards are required by Abseil.
    # there is no 1:1 mapping between Protobuf and Abseil versions, so this is not going to be
    # 100% accurate, but it should work for most cases.
    if ($major >= 30) {
        $system_provides->{'C++flags'} = "-std=c++17";
    } elsif ($major >= 21) {
        $system_provides->{'C++flags'} = "-std=c++14";
    } elsif ($major > 3 || ($major == 3 && $minor >= 6)) {
        $system_provides->{'C++flags'} = "-std=c++11";
    }
}

1;
