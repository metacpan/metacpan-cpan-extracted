package Beam::Runnable::AllowUsers;
our $VERSION = '0.014';
# ABSTRACT: Only allow certain users to run a command

#pod =head1 SYNOPSIS
#pod
#pod     ### In a Runnable module
#pod     package My::Runnable::Script;
#pod     use Moo;
#pod     with 'Beam::Runnable', 'Beam::Runnable::AllowUsers';
#pod     has '+allow_users' => ( default => [ 'root' ] );
#pod     sub run { }
#pod
#pod     ### In a container config file
#pod     runnable:
#pod         $class: My::Runnable::Script
#pod         $with:
#pod             - 'Beam::Runnable::AllowUsers'
#pod         allow_users:
#pod             - root
#pod             - doug
#pod
#pod =head1 DESCRIPTION
#pod
#pod This role checks to ensure that only certain users can run a command. If
#pod an unauthorized user runs the command, it dies with an error instead.
#pod
#pod B<NOTE:> This is mostly a demonstration of a L<Beam::Runnable> role.
#pod Users that can write to the configuration file can edit who is allowed
#pod to run the command, and there are other ways to prevent access to
#pod a file/command.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Runnable>, L<perlfunc/getpwuid>, L<< perlvar/$> >>
#pod
#pod =cut

use strict;
use warnings;
use Moo::Role;
use List::Util qw( any );
use Types::Standard qw( ArrayRef Str );

#pod =attr allow_users
#pod
#pod An array reference of user names that are allowed to run this task.
#pod
#pod =cut

has allow_users => (
    is => 'ro',
    isa => ArrayRef[ Str ],
    required => 1,
);

#pod =method run
#pod
#pod This role wraps the C<run> method of your runnable class to check that
#pod the user is authorized.
#pod
#pod =cut

before run => sub {
    my ( $self, @args ) = @_;
    my $user = getpwuid( $> );
    die "Unauthorized user: $user\n"
        unless any { $_ eq $user } @{ $self->allow_users };
};

1;

__END__

=pod

=head1 NAME

Beam::Runnable::AllowUsers - Only allow certain users to run a command

=head1 VERSION

version 0.014

=head1 SYNOPSIS

    ### In a Runnable module
    package My::Runnable::Script;
    use Moo;
    with 'Beam::Runnable', 'Beam::Runnable::AllowUsers';
    has '+allow_users' => ( default => [ 'root' ] );
    sub run { }

    ### In a container config file
    runnable:
        $class: My::Runnable::Script
        $with:
            - 'Beam::Runnable::AllowUsers'
        allow_users:
            - root
            - doug

=head1 DESCRIPTION

This role checks to ensure that only certain users can run a command. If
an unauthorized user runs the command, it dies with an error instead.

B<NOTE:> This is mostly a demonstration of a L<Beam::Runnable> role.
Users that can write to the configuration file can edit who is allowed
to run the command, and there are other ways to prevent access to
a file/command.

=head1 ATTRIBUTES

=head2 allow_users

An array reference of user names that are allowed to run this task.

=head1 METHODS

=head2 run

This role wraps the C<run> method of your runnable class to check that
the user is authorized.

=head1 SEE ALSO

L<Beam::Runnable>, L<perlfunc/getpwuid>, L<< perlvar/$> >>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
