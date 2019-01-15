package Beam::Runnable::Single;
our $VERSION = '0.015';
# ABSTRACT: Only allow one instance of this command at a time

#pod =head1 SYNOPSIS
#pod
#pod     ### In a Runnable module
#pod     package My::Runnable::Script;
#pod     use Moo;
#pod     with 'Beam::Runnable', 'Beam::Runnable::Single';
#pod     has '+pid_file' => ( default => '/var/run/runnable-script.pid' );
#pod     sub run { }
#pod
#pod     ### In a container config file
#pod     runnable:
#pod         $class: My::Runnable::Script
#pod         $with:
#pod             - 'Beam::Runnable::Single'
#pod         pid_file: /var/run/runnable-script.pid
#pod
#pod =head1 DESCRIPTION
#pod
#pod This role checks to ensure that only one instance of the command is
#pod running at a time. If another instance tries to run, it dies with an
#pod error instead.
#pod
#pod Users should have access to read/write the path pointed to by
#pod L</pid_file>, and to read/write the directory containing the PID file.
#pod
#pod If the command exits prematurely, the PID file will not be cleaned up.
#pod If this is undesirable, make sure to trap exceptions in your C<run()>
#pod method and return the exit code you want.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Runnable>
#pod
#pod =cut

use strict;
use warnings;
use Moo::Role;
use Types::Path::Tiny qw( Path );

#pod =attr pid_file
#pod
#pod The path to a file containing the PID of the currently-running script.
#pod
#pod =cut

has pid_file => (
    is => 'ro',
    isa => Path,
    required => 1,
    coerce => 1,
);

#pod =method run
#pod
#pod This role wraps the C<run> method of your runnable class to check that
#pod there is no running instance of this task (the PID file does not exist).
#pod
#pod =cut

before run => sub {
    my ( $self, @args ) = @_;
    if ( $self->pid_file->exists ) {
        my $pid = $self->pid_file->slurp;
        die "Process already running (PID: $pid)\n";
    }
    $self->pid_file->spew( $$ );
};

after run => sub {
    my ( $self ) = @_;
    unlink $self->pid_file;
};

1;

__END__

=pod

=head1 NAME

Beam::Runnable::Single - Only allow one instance of this command at a time

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    ### In a Runnable module
    package My::Runnable::Script;
    use Moo;
    with 'Beam::Runnable', 'Beam::Runnable::Single';
    has '+pid_file' => ( default => '/var/run/runnable-script.pid' );
    sub run { }

    ### In a container config file
    runnable:
        $class: My::Runnable::Script
        $with:
            - 'Beam::Runnable::Single'
        pid_file: /var/run/runnable-script.pid

=head1 DESCRIPTION

This role checks to ensure that only one instance of the command is
running at a time. If another instance tries to run, it dies with an
error instead.

Users should have access to read/write the path pointed to by
L</pid_file>, and to read/write the directory containing the PID file.

If the command exits prematurely, the PID file will not be cleaned up.
If this is undesirable, make sure to trap exceptions in your C<run()>
method and return the exit code you want.

=head1 ATTRIBUTES

=head2 pid_file

The path to a file containing the PID of the currently-running script.

=head1 METHODS

=head2 run

This role wraps the C<run> method of your runnable class to check that
there is no running instance of this task (the PID file does not exist).

=head1 SEE ALSO

L<Beam::Runnable>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
