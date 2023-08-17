package Alien::SDL3 0.04 {
    use strict;
    use warnings;
    use File::ShareDir;
    use Path::Tiny;
    use Config;
    use Alien::SDL3::ConfigData;
    #
    my $base = path( File::ShareDir::dist_dir('Alien-SDL3') );
    sub sdldir { $base; }

    sub incdir {
        sdldir->child('include');
    }

    sub libdir {
        sdldir->child('lib');
    }

    sub dynamic_libs {
        my $files = libdir->visit(
            sub {
                my ( $path, $state ) = @_;
                $state->{$path}++ if $path =~ m[\.$Config{so}([-\.][\d\.]+)?$];
            },
            { recurse => 1 }
        );
        keys %$files;
    }

    sub features {
        my ( $self, $feature ) = @_;
        return Alien::SDL3::ConfigData->feature($feature) if defined $feature;
        my %features = map { $_ => Alien::SDL3::ConfigData->feature($_) }
            qw[SDL3 SDL3_image SDL3_mixer SDL3_ttf];
        \%features;
    }
}
1;

=encoding utf-8

=head1 NAME

Alien::SDL3 - Build and install SDL3

=head1 SYNOPSIS

    use Alien::SDL3; # Don't.

=head1 DESCRIPTION

Alien::SDL3 builds and installs L<SDL3|https://github.com/libsdl-org/SDL/>,
L<SDL_image|https://github.com/libsdl-org/SDL_image/>,
L<SDL_mixer|https://github.com/libsdl-org/SDL_mixer/>, and
L<SDL_ttf|https://github.com/libsdl-org/SDL_ttf/>. It is not meant for direct
use. Just ignore it for now.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

