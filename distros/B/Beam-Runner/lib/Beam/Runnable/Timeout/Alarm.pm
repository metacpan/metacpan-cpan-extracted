package Beam::Runnable::Timeout::Alarm;
our $VERSION = '0.013';
# ABSTRACT: Use `alarm` to set a timeout for a command

#pod =head1 SYNOPSIS
#pod
#pod     ### In a Runnable module
#pod     package My::Runnable::Script;
#pod     use Moo;
#pod     with 'Beam::Runnable', 'Beam::Runnable::Timeout::Alarm';
#pod     has '+timeout' => ( default => 60 ); # Set timeout: 60s
#pod     sub run { }
#pod
#pod     ### In a container config file
#pod     runnable:
#pod         $class: My::Runnable::Script
#pod         $with:
#pod             - 'Beam::Runnable::Timeout::Alarm'
#pod         timeout: 60
#pod
#pod =head1 DESCRIPTION
#pod
#pod This role adds a timeout for a runnable module using Perl's L<alarm()|perlfunc/alarm>
#pod function. When the timeout is reached, a warning will be printed to C<STDERR> and the
#pod program will exit with code C<255>.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Runnable>, L<perlfunc/alarm>, L<Time::HiRes>
#pod
#pod =cut

use strict;
use warnings;
use Moo::Role;
use Types::Standard qw( Num CodeRef );
use Time::HiRes qw( alarm );

#pod =attr timeout
#pod
#pod The time in seconds this program is allowed to run. This can include
#pod a decimal (like C<6.5> seconds).
#pod
#pod =cut

has timeout => (
    is => 'ro',
    isa => Num,
    required => 1,
);

#pod =attr _timeout_cb
#pod
#pod A callback to be run when the timeout is reached. Override this to change
#pod what warning is printed to C<STDERR> and what exit code is used (or whether
#pod the process exits at all).
#pod
#pod =cut

has _timeout_cb => (
    is => 'ro',
    isa => CodeRef,
    default => sub {
        warn "Timeout reached!\n";
        exit 255;
    },
);

#pod =method run
#pod
#pod This role wraps the C<run> method of your runnable class to add the timeout.
#pod
#pod =cut

around run => sub {
    my ( $orig, $self, @args ) = @_;
    local $SIG{ALRM} = $self->_timeout_cb;
    alarm $self->timeout;
    return $self->$orig( @args );
};

1;

__END__

=pod

=head1 NAME

Beam::Runnable::Timeout::Alarm - Use `alarm` to set a timeout for a command

=head1 VERSION

version 0.013

=head1 SYNOPSIS

    ### In a Runnable module
    package My::Runnable::Script;
    use Moo;
    with 'Beam::Runnable', 'Beam::Runnable::Timeout::Alarm';
    has '+timeout' => ( default => 60 ); # Set timeout: 60s
    sub run { }

    ### In a container config file
    runnable:
        $class: My::Runnable::Script
        $with:
            - 'Beam::Runnable::Timeout::Alarm'
        timeout: 60

=head1 DESCRIPTION

This role adds a timeout for a runnable module using Perl's L<alarm()|perlfunc/alarm>
function. When the timeout is reached, a warning will be printed to C<STDERR> and the
program will exit with code C<255>.

=head1 ATTRIBUTES

=head2 timeout

The time in seconds this program is allowed to run. This can include
a decimal (like C<6.5> seconds).

=head2 _timeout_cb

A callback to be run when the timeout is reached. Override this to change
what warning is printed to C<STDERR> and what exit code is used (or whether
the process exits at all).

=head1 METHODS

=head2 run

This role wraps the C<run> method of your runnable class to add the timeout.

=head1 SEE ALSO

L<Beam::Runnable>, L<perlfunc/alarm>, L<Time::HiRes>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
