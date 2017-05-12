package My::ModuleBuild;

use strict;
use warnings;
use base 'Alien::Base::ModuleBuild';
use File::Spec;
use Config;

sub alien_check_installed_version {
    my ($self) = @_;

    my $b = $self->cbuilder;

    my $obj = eval {
        $b->compile(
            source               => File::Spec->catfile(qw( inc My test.c )),
            extra_compiler_flags => $self->alien_provides_cflags,
        );
    };

    return unless defined $obj;

    $self->add_to_cleanup($obj);

    my ( $exe, @rest ) = eval {
        $b->link_executable(
            objects            => [$obj],
            extra_linker_flags => $self->alien_provides_libs,
        );
    };

    unlink $obj;

    return unless defined $exe;

    $self->add_to_cleanup( $exe, @rest );

    if ( `$exe` =~ /version=([0-9\.]+)/ ) {
        my $version = $1;
        unlink $exe, @rest;

        # requires version 6.x (or better?)
        return unless $version =~ /^([0-9]+)/ && $1 >= 6;
        return $version;
    }
    return;
}

1;
