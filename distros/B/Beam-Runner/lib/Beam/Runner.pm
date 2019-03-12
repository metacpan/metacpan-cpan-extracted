package Beam::Runner;
our $VERSION = '0.016';
# ABSTRACT: Configure, list, document, and execute runnable task objects

#pod =head1 SYNOPSIS
#pod
#pod     beam run <container> <task> [<args...>]
#pod     beam list
#pod     beam list <container>
#pod     beam help <container> <task>
#pod     beam help
#pod
#pod =head1 DESCRIPTION
#pod
#pod This distribution is an execution and organization system for runnable
#pod objects (tasks). This allows you to prepare a list of runnable tasks in
#pod configuration files and then execute them. This also allows easy
#pod discovery of configuration files and objects, and allows you to document
#pod your objects for your users.
#pod
#pod =head2 Tasks
#pod
#pod A task is an object that consumes the L<Beam::Runnable> role. This role
#pod requires only a C<run()> method be implemented in the class. This
#pod C<run()> method should accept all the arguments given on the command
#pod line. It can parse GNU-style options out of this array using
#pod L<Getopt::Long/GetOptionsFromArray>.
#pod
#pod Task modules can compose additional roles to easily add more features,
#pod like adding a timeout with L<Beam::Runnable::Timeout::Alarm>.
#pod
#pod Task modules are expected to have documentation that will be displayed
#pod by the C<beam list> and C<beam help> commands. The C<beam list> command
#pod will display the C<NAME> section of the documentation, and the C<beam
#pod help> command will display the C<NAME>, C<SYNOPSIS>, C<DESCRIPTION>,
#pod C<ARGUMENTS>, C<OPTIONS>, C<ENVIRONMENT>, and C<SEE ALSO> sections of
#pod the documentation.
#pod
#pod =head2 Configuration Files
#pod
#pod The configuration file is a L<Beam::Wire> container file that describes
#pod objects. Some of these objects are marked as executable tasks by
#pod consuming the L<Beam::Runnable> role.
#pod
#pod The container file can have a special entry called C<$summary> which
#pod has a short summary that will be displayed when using the C<beam list>
#pod command.
#pod
#pod Here's an example container file that has a summary, configures
#pod a L<DBIx::Class> schema (using the schema class for CPAN Testers:
#pod L<CPAN::Testers::Schema>), and configures a runnable task called
#pod C<to_metabase> located in the class
#pod C<CPAN::Testers::Backend::Migrate::ToMetabase>:
#pod
#pod     # migrate.yml
#pod     $summary: Migrate data between databases
#pod
#pod     _schema:
#pod         $class: CPAN::Testers::Schema
#pod         $method: connect_from_config
#pod
#pod     to_metabase:
#pod         $class: CPAN::Testers::Backend::Migrate::ToMetabase
#pod         schema:
#pod             $ref: _schema
#pod
#pod For more information about container files, see L<the Beam::Wire
#pod documentation|Beam::Wire>.
#pod
#pod =head1 QUICKSTART
#pod
#pod Here's a short tutorial for getting started with C<Beam::Runner>. If you
#pod want to try it yourself, start with an empty directory.
#pod
#pod =head2 Create a Task
#pod
#pod To create a task, make a Perl module that uses the L<Beam::Runnable> role
#pod and implements a C<run> method. For an example, let's create a task that
#pod prints C<Hello, World!> to the screen.
#pod
#pod     package My::Runnable::Greeting;
#pod     use Moo;
#pod     with 'Beam::Runnable';
#pod     sub run {
#pod         my ( $self, @args ) = @_;
#pod         print "Hello, World!\n";
#pod     }
#pod     1;
#pod
#pod If you're following along, save this in the
#pod C<lib/My/Runnable/Greeting.pm> file.
#pod
#pod =head2 Create a Configuration File
#pod
#pod Now that we have a task to run, we need to create a configuration file
#pod (or a "container"). The configuration file is a YAML file that describes
#pod all the tasks we can run. Let's create an C<etc> directory and name our
#pod container file C<etc/greet.yml>.
#pod
#pod Inside this file, we define our task. We have to give our task a simple
#pod name, like C<hello>. Then we have to say what task class to run (in our case,
#pod C<My::Runnable::Greeting>).
#pod
#pod     hello:
#pod         $class: My::Runnable::Greeting
#pod
#pod =head2 Run the Task
#pod
#pod Now we can run our task. Before we do, we need to tell C<Beam::Runner> where
#pod to find our code and our configuration by setting some environment variables:
#pod
#pod     $ export PERL5LIB=lib:$PERL5LIB
#pod     $ export BEAM_PATH=etc
#pod
#pod The C<PERL5LIB> environment variable adds directories for C<perl> to search
#pod for modules (like our task module). The C<BEAM_PATH> environment variable
#pod adds directories to search for configuration files (like ours).
#pod
#pod To validate that our environment variables are set correctly, we can list the
#pod tasks:
#pod
#pod     $ beam list
#pod     greet
#pod     - hello -- My::Runnable::Greeting
#pod
#pod The C<beam list> command looks through our C<BEAM_PATH> directory, opens
#pod all the configuration files it finds, and lists all the
#pod L<Beam::Runnable> objects inside (helpfully giving us the module name for us
#pod to find documentation).
#pod
#pod Then, to run the command, we use C<beam run> and give it the configuration file
#pod (C<greet>) and the task (C<hello>):
#pod
#pod     $ beam run greet hello
#pod     Hello, World!
#pod
#pod =head2 Adding Documentation
#pod
#pod Part of the additional benefits of defining tasks in L<Beam::Runnable> modules
#pod is that the C<beam help> command will show the documentation for the task. To
#pod do this, we must add documentation to our module.
#pod
#pod This documentation is done as L<POD|perlpod>, Perl's system of documentation.
#pod Certain sections of the documentation will be shown: C<NAME>, C<SYNOPSIS>,
#pod C<DESCRIPTION>, C<ARGUMENTS>, C<OPTIONS>, and C<SEE ALSO>.
#pod
#pod     =head1 NAME
#pod
#pod     My::Runnable::Greeting - Greet the user
#pod
#pod     =head1 SYNOPSIS
#pod
#pod         beam run greet hello
#pod
#pod     =head1 DESCRIPTION
#pod
#pod     This task greets the user warmly and then exits.
#pod
#pod     =head1 ARGUMENTS
#pod
#pod     No arguments are allowed during a greeting.
#pod
#pod     =head1 OPTIONS
#pod
#pod     Greeting warmly is the only option.
#pod
#pod     =head1 SEE ALSO
#pod
#pod     L<Beam::Runnable>
#pod
#pod If we add this documentation to our C<lib/My/Runnable/Greeting.pm> file,
#pod we can then run C<beam help> to see the documentation:
#pod
#pod     $ beam help greet hello
#pod     NAME
#pod         My::Runnable::Greeting - Greet the user
#pod
#pod     SYNOPSIS
#pod             beam run greet hello
#pod
#pod     DESCRIPTION
#pod         This task greets the user warmly and then exits.
#pod
#pod     ARGUMENTS
#pod         No arguments are allowed during a greeting.
#pod
#pod     OPTIONS
#pod         Greeting warmly is the only option.
#pod
#pod     SEE ALSO
#pod         Beam::Runnable
#pod
#pod The C<beam list> command will also use our new documentation to show the C<NAME>
#pod section:
#pod
#pod     $ beam list
#pod     greet
#pod     - hello -- My::Runnable::Greeting - Greet the user
#pod
#pod =head2 Going Further
#pod
#pod For more information on how to use the configuration file to create more
#pod complex objects like database connections, see
#pod L<Beam::Wire::Help::Config>.
#pod
#pod To learn how to run your tasks using a distributed job queue to
#pod parallelize and improve performance, see L<Beam::Minion>.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<beam>, L<Beam::Runnable>, L<Beam::Wire>
#pod
#pod =cut

use strict;
use warnings;



1;

__END__

=pod

=head1 NAME

Beam::Runner - Configure, list, document, and execute runnable task objects

=head1 VERSION

version 0.016

=head1 SYNOPSIS

    beam run <container> <task> [<args...>]
    beam list
    beam list <container>
    beam help <container> <task>
    beam help

=head1 DESCRIPTION

This distribution is an execution and organization system for runnable
objects (tasks). This allows you to prepare a list of runnable tasks in
configuration files and then execute them. This also allows easy
discovery of configuration files and objects, and allows you to document
your objects for your users.

=head2 Tasks

A task is an object that consumes the L<Beam::Runnable> role. This role
requires only a C<run()> method be implemented in the class. This
C<run()> method should accept all the arguments given on the command
line. It can parse GNU-style options out of this array using
L<Getopt::Long/GetOptionsFromArray>.

Task modules can compose additional roles to easily add more features,
like adding a timeout with L<Beam::Runnable::Timeout::Alarm>.

Task modules are expected to have documentation that will be displayed
by the C<beam list> and C<beam help> commands. The C<beam list> command
will display the C<NAME> section of the documentation, and the C<beam
help> command will display the C<NAME>, C<SYNOPSIS>, C<DESCRIPTION>,
C<ARGUMENTS>, C<OPTIONS>, C<ENVIRONMENT>, and C<SEE ALSO> sections of
the documentation.

=head2 Configuration Files

The configuration file is a L<Beam::Wire> container file that describes
objects. Some of these objects are marked as executable tasks by
consuming the L<Beam::Runnable> role.

The container file can have a special entry called C<$summary> which
has a short summary that will be displayed when using the C<beam list>
command.

Here's an example container file that has a summary, configures
a L<DBIx::Class> schema (using the schema class for CPAN Testers:
L<CPAN::Testers::Schema>), and configures a runnable task called
C<to_metabase> located in the class
C<CPAN::Testers::Backend::Migrate::ToMetabase>:

    # migrate.yml
    $summary: Migrate data between databases

    _schema:
        $class: CPAN::Testers::Schema
        $method: connect_from_config

    to_metabase:
        $class: CPAN::Testers::Backend::Migrate::ToMetabase
        schema:
            $ref: _schema

For more information about container files, see L<the Beam::Wire
documentation|Beam::Wire>.

=head1 QUICKSTART

Here's a short tutorial for getting started with C<Beam::Runner>. If you
want to try it yourself, start with an empty directory.

=head2 Create a Task

To create a task, make a Perl module that uses the L<Beam::Runnable> role
and implements a C<run> method. For an example, let's create a task that
prints C<Hello, World!> to the screen.

    package My::Runnable::Greeting;
    use Moo;
    with 'Beam::Runnable';
    sub run {
        my ( $self, @args ) = @_;
        print "Hello, World!\n";
    }
    1;

If you're following along, save this in the
C<lib/My/Runnable/Greeting.pm> file.

=head2 Create a Configuration File

Now that we have a task to run, we need to create a configuration file
(or a "container"). The configuration file is a YAML file that describes
all the tasks we can run. Let's create an C<etc> directory and name our
container file C<etc/greet.yml>.

Inside this file, we define our task. We have to give our task a simple
name, like C<hello>. Then we have to say what task class to run (in our case,
C<My::Runnable::Greeting>).

    hello:
        $class: My::Runnable::Greeting

=head2 Run the Task

Now we can run our task. Before we do, we need to tell C<Beam::Runner> where
to find our code and our configuration by setting some environment variables:

    $ export PERL5LIB=lib:$PERL5LIB
    $ export BEAM_PATH=etc

The C<PERL5LIB> environment variable adds directories for C<perl> to search
for modules (like our task module). The C<BEAM_PATH> environment variable
adds directories to search for configuration files (like ours).

To validate that our environment variables are set correctly, we can list the
tasks:

    $ beam list
    greet
    - hello -- My::Runnable::Greeting

The C<beam list> command looks through our C<BEAM_PATH> directory, opens
all the configuration files it finds, and lists all the
L<Beam::Runnable> objects inside (helpfully giving us the module name for us
to find documentation).

Then, to run the command, we use C<beam run> and give it the configuration file
(C<greet>) and the task (C<hello>):

    $ beam run greet hello
    Hello, World!

=head2 Adding Documentation

Part of the additional benefits of defining tasks in L<Beam::Runnable> modules
is that the C<beam help> command will show the documentation for the task. To
do this, we must add documentation to our module.

This documentation is done as L<POD|perlpod>, Perl's system of documentation.
Certain sections of the documentation will be shown: C<NAME>, C<SYNOPSIS>,
C<DESCRIPTION>, C<ARGUMENTS>, C<OPTIONS>, and C<SEE ALSO>.

    =head1 NAME

    My::Runnable::Greeting - Greet the user

    =head1 SYNOPSIS

        beam run greet hello

    =head1 DESCRIPTION

    This task greets the user warmly and then exits.

    =head1 ARGUMENTS

    No arguments are allowed during a greeting.

    =head1 OPTIONS

    Greeting warmly is the only option.

    =head1 SEE ALSO

    L<Beam::Runnable>

If we add this documentation to our C<lib/My/Runnable/Greeting.pm> file,
we can then run C<beam help> to see the documentation:

    $ beam help greet hello
    NAME
        My::Runnable::Greeting - Greet the user

    SYNOPSIS
            beam run greet hello

    DESCRIPTION
        This task greets the user warmly and then exits.

    ARGUMENTS
        No arguments are allowed during a greeting.

    OPTIONS
        Greeting warmly is the only option.

    SEE ALSO
        Beam::Runnable

The C<beam list> command will also use our new documentation to show the C<NAME>
section:

    $ beam list
    greet
    - hello -- My::Runnable::Greeting - Greet the user

=head2 Going Further

For more information on how to use the configuration file to create more
complex objects like database connections, see
L<Beam::Wire::Help::Config>.

To learn how to run your tasks using a distributed job queue to
parallelize and improve performance, see L<Beam::Minion>.

=head1 SEE ALSO

L<beam>, L<Beam::Runnable>, L<Beam::Wire>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
