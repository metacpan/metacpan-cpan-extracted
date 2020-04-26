package Code::TidyAll::Plugin::GenericValidator;

use strict;
use warnings;

use Moo;

extends 'Code::TidyAll::Plugin';

with 'Code::TidyAll::Role::GenericExecutable';

our $VERSION = '0.78';

sub validate_file {
    my $self = shift;
    my $file = shift;

    $self->_run_generic_executable_or_die($file);

    return;
}

1;

# ABSTRACT: A plugin to run any executable as a validator

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::GenericValidator - A plugin to run any executable as a
validator

=head1 VERSION

version 0.78

=head1 SYNOPSIS

    # In your tidyall config
    [GenericValidator / JSONOrderedTidy]
    cmd = json-ordered-tidy
    argv = -check
    ok_exit_codes = 0 1

=head1 DESCRIPTION

This plugin allows you to define any executable as a validator.

=head1 CONFIGURATION

This plugin accepts the following configuration options:

=head2 cmd

This is the command to be run. This is required.

=head2 argv

This is a string containing additional arguments to be passed to the command.
These arguments will always be passed.

=head2 file_flag

This is the flag used to tell the command what file to operate on, if it has
one.

By default, the file is simply passed as the last argument. However, many
commands will want this passed with a flag like C<-f>, C<--file>, or
C<--input>.

=head2 ok_exit_codes

By default, any exit code other than C<0> is considered an exception. However,
many commands use their exit code to indicate that there was a validation issue
as opposed to an exception.

You can specify multiple exit codes either by listing C<ok_exit_codes> multiple
times or as a space-separate list.

=head1 SUPPORT

Bugs may be submitted at
L<https://github.com/houseabsolute/perl-code-tidyall/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Code-TidyAll can be found at
L<https://github.com/houseabsolute/perl-code-tidyall>.

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2020 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with
this distribution.

=cut
