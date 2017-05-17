package Code::TidyAll::Plugin::JSLint;

use strict;
use warnings;

use IPC::Run3 qw(run3);

use Moo;

extends 'Code::TidyAll::Plugin';

our $VERSION = '0.59';

sub _build_cmd {'jslint'}

sub validate_file {
    my ( $self, $file ) = @_;

    my $cmd = sprintf( '%s %s %s', $self->cmd, $self->argv, $file );
    my $output;
    run3( $cmd, \undef, \$output, \$output );
    die "$output\n" if $output !~ /is OK\./;
}

1;

# ABSTRACT: Use jslint with tidyall

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::JSLint - Use jslint with tidyall

=head1 VERSION

version 0.59

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

=over

=item argv

Arguments to pass to jslint

=item cmd

Full path to jslint

=back

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

This software is copyright (c) 2011 - 2017 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with
this distribution.

=cut
