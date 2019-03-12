package Beam::Runnable;
our $VERSION = '0.016';
# ABSTRACT: Role for runnable objects

#pod =head1 SYNOPSIS
#pod
#pod     package My::Runnable;
#pod     use Moo;
#pod     with 'Beam::Runnable';
#pod     sub run { ... }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This role declares your object as runnable by the C<beam run> command.
#pod Runnable objects will be listed by the C<beam list> command, and their
#pod documentation displayed by the C<beam help> command.
#pod
#pod =head2 The C<run> method
#pod
#pod The C<run> method is the main function of your object. See below for its
#pod arguments and return value.
#pod
#pod The C<run> method should be as small as possible, ideally only parsing
#pod command-line arguments and delegating to other objects to do the real
#pod work. Though your runnable object can be used in other code, the API of
#pod the C<run> method is a terrible way to do that, and it is better to keep
#pod your business logic and other important code in another class.
#pod
#pod =head2 Documentation
#pod
#pod The C<beam help> command will display the documentation of your module:
#pod the C<NAME> (abstract), C<SYNOPSIS>, C<DESCRIPTION>, C<ARGUMENTS>,
#pod C<OPTIONS>, and C<SEE ALSO> sections. This is the same as what
#pod L<Pod::Usage> produces by default.
#pod
#pod The C<beam list> command, when listing runnable objects, will display
#pod either the C<summary> attribute or the C<NAME> POD section (abstract)
#pod next to the service name.
#pod
#pod =head2 Additional Roles
#pod
#pod Additional roles can add common functionality to your runnable script.
#pod Some of these are included in the C<Beam::Runner> distribution:
#pod
#pod =over
#pod
#pod =item L<Beam::Runnable::Timeout::Alarm>
#pod
#pod This role will add a timeout using Perl's built-in
#pod L<alarm()|perlfunc/alarm> function. Once the timeout is reached, the
#pod program will print a warning and exit with an error code.
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<beam>, L<Beam::Runner>
#pod
#pod =cut

use strict;
use warnings;
use Moo::Role;
with 'Beam::Service';
use Types::Standard qw( Str );

#pod =attr summary
#pod
#pod A summary of the task to be run. This will be displayed by the C<beam
#pod list> command in the list.
#pod
#pod =cut

has summary => (
    is => 'ro',
    isa => Str,
);

#pod =method run
#pod
#pod     my $exit_code = $obj->run( @argv );
#pod
#pod Execute the runnable object with the given arguments and returning the
#pod exit status. C<@argv> is passed-in from the command line and may contain
#pod options (which you can parse using L<Getopt::Long's GetOptionsFromArray
#pod function|Getopt::Long/Parsing options from an arbitrary array>.
#pod
#pod =cut

requires 'run';

1;

__END__

=pod

=head1 NAME

Beam::Runnable - Role for runnable objects

=head1 VERSION

version 0.016

=head1 SYNOPSIS

    package My::Runnable;
    use Moo;
    with 'Beam::Runnable';
    sub run { ... }

=head1 DESCRIPTION

This role declares your object as runnable by the C<beam run> command.
Runnable objects will be listed by the C<beam list> command, and their
documentation displayed by the C<beam help> command.

=head2 The C<run> method

The C<run> method is the main function of your object. See below for its
arguments and return value.

The C<run> method should be as small as possible, ideally only parsing
command-line arguments and delegating to other objects to do the real
work. Though your runnable object can be used in other code, the API of
the C<run> method is a terrible way to do that, and it is better to keep
your business logic and other important code in another class.

=head2 Documentation

The C<beam help> command will display the documentation of your module:
the C<NAME> (abstract), C<SYNOPSIS>, C<DESCRIPTION>, C<ARGUMENTS>,
C<OPTIONS>, and C<SEE ALSO> sections. This is the same as what
L<Pod::Usage> produces by default.

The C<beam list> command, when listing runnable objects, will display
either the C<summary> attribute or the C<NAME> POD section (abstract)
next to the service name.

=head2 Additional Roles

Additional roles can add common functionality to your runnable script.
Some of these are included in the C<Beam::Runner> distribution:

=over

=item L<Beam::Runnable::Timeout::Alarm>

This role will add a timeout using Perl's built-in
L<alarm()|perlfunc/alarm> function. Once the timeout is reached, the
program will print a warning and exit with an error code.

=back

=head1 ATTRIBUTES

=head2 summary

A summary of the task to be run. This will be displayed by the C<beam
list> command in the list.

=head1 METHODS

=head2 run

    my $exit_code = $obj->run( @argv );

Execute the runnable object with the given arguments and returning the
exit status. C<@argv> is passed-in from the command line and may contain
options (which you can parse using L<Getopt::Long's GetOptionsFromArray
function|Getopt::Long/Parsing options from an arbitrary array>.

=head1 SEE ALSO

L<beam>, L<Beam::Runner>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
