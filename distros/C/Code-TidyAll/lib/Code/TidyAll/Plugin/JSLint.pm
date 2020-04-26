package Code::TidyAll::Plugin::JSLint;

use strict;
use warnings;

use Moo;

extends 'Code::TidyAll::Plugin';

with 'Code::TidyAll::Role::RunsCommand';

has '+ok_exit_codes' => (
    default => sub { [ 0, 1 ] },
);

our $VERSION = '0.78';

sub _build_cmd {'jslint'}

sub validate_file {
    my ( $self, $file ) = @_;

    my $output = $self->_run_or_die($file);
    die "$output\n" if $output =~ /\S/ && $output !~ /.+ is OK\./;

    return;
}

1;

# ABSTRACT: Use jslint with tidyall

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::JSLint - Use jslint with tidyall

=head1 VERSION

version 0.78

=head1 SYNOPSIS

   In configuration:

   [JSLint]
   select = static/**/*.js
   argv = --white --vars --regex

=head1 DESCRIPTION

Runs L<jslint|http://www.jslint.com/>, a JavaScript validator, and dies if any
problems were found.

=head1 INSTALLATION

Install L<npm|https://npmjs.org/>, then run

    npm install jslint

=head1 CONFIGURATION

This plugin accepts the following configuration options:

=head2 argv

Arguments to pass to C<jslint>.

=head2 cmd

The path for the C<jslint> command. By default this is just C<jslint>, meaning
that the user's C<PATH> will be searched for the command.

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
