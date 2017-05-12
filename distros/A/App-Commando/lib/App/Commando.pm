package App::Commando;

use strict;
use warnings;

# ABSTRACT: Flexible library to build command-line apps

our $VERSION = '0.012'; # VERSION

use App::Commando::Program;

sub program {
    my ($name) = @_;

    my $program = App::Commando::Program->new($name);

    return $program;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Commando - Flexible library to build command-line apps

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    use App::Commando;

    my $program = App::Commando::program('example');
    $program->version('0.42');

    my $cmd_hello = $program->command('hello');
    $cmd_hello->syntax('hello TARGET');
    $cmd_hello->option('world', '-w', '--world', 'Say hello to the World');
    $cmd_hello->option('universe', '-u', '--universe', 'Say hello to the Universe');
    $cmd_hello->action(sub {
        my ($argv, $config) = @_;

        # Get the first argument or set the default value
        my $target = $argv->[0] || 'Everyone';
        $target = "World" if $config->{world};
        $target = "Universe" if $config->{universe};

        print "Hello, $target!\n";
    });

    my $cmd_bye = $program->command('bye');
    $cmd_bye->action(sub {
        print "Goodbye!\n";
    });

    $program->go;

=head1 DESCRIPTION

App::Commando is a lightweight library for building command-line applications,
based on Ruby's Mercenary.

=head1 USAGE

=head2 App::Commando

=head3 C<App::Commando::program($name)>

Creates a new instance of App::Commando::Program. Arguments:

=over

=item C<$name>

Program name.

=back

Example:

    my $program = App::Commando::program('example');

=head2 Program

App::Commando::Program extends App::Commando::Command, so it inherits all its
methods.

=head3 C<new($name)>

Creates a new instance of App::Commando::Program. Arguments:

=over

=item C<$name>

Program name.

=back

Example:

    my $program = App::Commando::Program->new('example');

=head2 Command

=head3 C<new($name, $parent)>

Creates a new instance of App::Commando::Command. Arguments:

=over

=item C<$name>

New command name.

=item C<$parent>

Parent command (optional).

=back

Example:

    my $cmd = App::Commando::Command->new('foo');
    my $sub_cmd = App::Commando::Command->new('bar', $cmd);

=head3 C<version($version)>

Gets or sets the version of the command. Arguments:

=over

=item C<$version>

New version to set (optional).

=back

Example:

    $cmd->version('1.2.3');
    print $cmd->version;        # '1.2.3'

=head3 C<syntax($syntax)>

Gets or sets command syntax. Arguments:

=over

=item C<$syntax>

The syntax to set for the command (optional).

=back

Example:

    $cmd->syntax('foo <SUBCOMMAND> [OPTIONS]');
    print $cmd->syntax;         # 'foo <SUBCOMMAND> [OPTIONS]'

=head3 C<description($description)>

Gets or sets command description. Arguments:

=over

=item C<$description>

The description to set for the command (optional).

=back

Example:

    $cmd->description('Does whatever.');
    print $cmd->description;    # 'Does whatever.'

=head3 C<default_command($command_name)>

Gets or sets the default subcommand to execute when no command name is passed to
the program. Arguments:

=over

=item C<$default_command>

The name of the subcommand to be set as the default (optional).

=back

Example:

    $cmd->default_command('bar');
    $cmd->default_command;      # An instance of App::Commando::Command

=head3 C<option($config_key, ...)>

Adds a new option to the command. Arguments:

=over

=item C<$config_key>

The configuration key that this option corresponds to.

=back

The remaining arguments are optional, and are processed based on their content:

=over

=item *

If the argument starts with a single dash (e.g., C<'-x'>), it is assumed to be
the short switch for the option.

=item *

If the argument starts with a double dash (e.g., C<'--xyzzy'>), it is assumed to
be the long switch for the option.

=item *

If the argument is formatted like a Getopt::Long option specification (e.g.,
C<'=s'>), it is passed as the specification to Getopt::Long when command-line
arguments are parsed. See L<Getopt::Long/"Summary of Option Specifications"> for
more information.

=item *

Otherwise, the argument is assumed to be the option description (e.g.,
C<'Enables xyzzy mode'>).

=back

Example:

    $cmd->option('xyzzy', '-x', '--xyzzy', 'Enables xyzzy mode');

=head3 C<alias($command_name)>

Adds an alias for this command, allowing the command to be executed using a
different name. Arguments:

=over

=item C<$command_name>

The alias for this command.

=back

Example:

    $cmd->alias('other');

=head3 C<action($code)>

Adds a code block to be run when the command is called. Arguments:

=over

=item C<$code>

The code block to be executed.

=back

The code block is passed two arguments:

=over

=item C<$argv>

An array reference containing non-switch arguments from the command-line.

=item C<$config>

A hash reference containing configuration options that were passed using
switches.

=back

Example:

    $cmd->action(sub {
        my ($argv, $config) = @_;

        if ($config->{xyzzy}) {
            # ...
        }
    });

=head3 C<command($command_name)>

Adds a new subcommand to this command. Arguments:

=over

=item C<$command_name>

The name of the new subcommand.

=back

Example:

    my $sub_cmd = $cmd->command('bar');

=head1 ACKNOWLEDGEMENTS

The design of this library is based on Mercenary, written by Parker Moore.

=head1 SEE ALSO

=over 4

=item *

L<Getopt::Long>

=item *

L<https://github.com/jekyll/mercenary> - Mercenary GitHub repository

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/odyniec/p5-App-Commando/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/odyniec/p5-App-Commando>

  git clone https://github.com/odyniec/p5-App-Commando.git

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
