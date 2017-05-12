package MyBuild;

use strict;
use warnings;

use base 'Module::Build';

sub ACTION_code {
    my $self = shift;

    if ( $self->have_c_compiler() ) {
        my $b = $self->cbuilder();

        my $obj_file = $b->compile(
            source => 'bin/dispatch.c',
        );
        my $exe_file = $b->link_executable( objects => $obj_file );

        $self->add_to_cleanup( $obj_file, $exe_file );
    }
    else {
        die "No C compiler found.\n";
    }

    return $self->SUPER::ACTION_code;
}

1;
