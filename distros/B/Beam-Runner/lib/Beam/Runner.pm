package Beam::Runner;
our $VERSION = '0.009';
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
#pod =head2 Tasks
#pod
#pod A task is an object configured in the container file that consumes the
#pod L<Beam::Runnable> role. This role requires only a C<run()> method be
#pod implemented in the class.
#pod
#pod Task modules are expected to have documentation that will be displayed
#pod by the C<beam list> and C<beam help> commands. The C<beam list> command
#pod will display the C<NAME> section of the documentation, and the C<beam
#pod help> command will display the C<NAME>, C<SYNOPSIS>, C<DESCRIPTION>,
#pod C<ARGUMENTS>, C<OPTIONS>, C<ENVIRONMENT>, and C<SEE ALSO> sections of
#pod the documentation.
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

version 0.009

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

=head2 Tasks

A task is an object configured in the container file that consumes the
L<Beam::Runnable> role. This role requires only a C<run()> method be
implemented in the class.

Task modules are expected to have documentation that will be displayed
by the C<beam list> and C<beam help> commands. The C<beam list> command
will display the C<NAME> section of the documentation, and the C<beam
help> command will display the C<NAME>, C<SYNOPSIS>, C<DESCRIPTION>,
C<ARGUMENTS>, C<OPTIONS>, C<ENVIRONMENT>, and C<SEE ALSO> sections of
the documentation.

=head1 SEE ALSO

L<beam>, L<Beam::Runnable>, L<Beam::Wire>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
