package Beam::Make::File;
our $VERSION = '0.003';
# ABSTRACT: A Beam::Make recipe to build a file from shell scripts

#pod =head1 SYNOPSIS
#pod
#pod     ### Beamfile
#pod     a.out:
#pod         requires:
#pod             - main.c
#pod         commands:
#pod             - cc -Wall main.c
#pod
#pod =head1 DESCRIPTION
#pod
#pod This L<Beam::Make> recipe class creates a file by running one or more
#pod shell scripts. The recipe's name should be the file that will be created
#pod by the recipe.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Make>, L<Beam::Wire>, L<DBI>
#pod
#pod =cut

use v5.20;
use warnings;
use Moo;
use File::stat;
use Time::Piece;
use Digest::SHA;
use experimental qw( signatures postderef );

extends 'Beam::Make::Recipe';

#pod =attr commands
#pod
#pod An array of commands to run. Commands can be strings, which will be interpreted by
#pod the shell, or arrays, which will be invoked directly by the system.
#pod
#pod     # Interpreted as a shell script. Pipes, environment variables, redirects,
#pod     # etc... allowed
#pod     - cc -Wall main.c
#pod
#pod     # `cc` invoked directly. Shell functions will not work.
#pod     - [ cc, -Wall, main.c ]
#pod
#pod     # A single, multi-line shell script
#pod     - |
#pod         if [ $( date ) -gt $DATE ]; then
#pod             echo Another day $( date ) >> /var/log/calendar.log
#pod         fi
#pod
#pod =cut

has commands => ( is => 'ro', required => 1 );

sub make( $self, %vars ) {
    for my $cmd ( $self->commands->@* ) {
        my @cmd = ref $cmd eq 'ARRAY' ? @$cmd : ( $cmd );
        system @cmd;
        if ( $? != 0 ) {
            die sprintf 'Error running external command "%s": %s', "@cmd", $?;
        }
    }
    # XXX: If the recipe does not create the file, throw an error
    $self->cache->set( $self->name, $self->_cache_hash );
    return 0;
}

sub _cache_hash( $self ) {
    return -e $self->name ? Digest::SHA->new( 1 )->addfile( $self->name )->b64digest : '';
}

sub last_modified( $self ) {
    return -e $self->name ? $self->cache->last_modified( $self->name, $self->_cache_hash ) : 0;
}

1;

__END__

=pod

=head1 NAME

Beam::Make::File - A Beam::Make recipe to build a file from shell scripts

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    ### Beamfile
    a.out:
        requires:
            - main.c
        commands:
            - cc -Wall main.c

=head1 DESCRIPTION

This L<Beam::Make> recipe class creates a file by running one or more
shell scripts. The recipe's name should be the file that will be created
by the recipe.

=head1 ATTRIBUTES

=head2 commands

An array of commands to run. Commands can be strings, which will be interpreted by
the shell, or arrays, which will be invoked directly by the system.

    # Interpreted as a shell script. Pipes, environment variables, redirects,
    # etc... allowed
    - cc -Wall main.c

    # `cc` invoked directly. Shell functions will not work.
    - [ cc, -Wall, main.c ]

    # A single, multi-line shell script
    - |
        if [ $( date ) -gt $DATE ]; then
            echo Another day $( date ) >> /var/log/calendar.log
        fi

=head1 SEE ALSO

L<Beam::Make>, L<Beam::Wire>, L<DBI>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
