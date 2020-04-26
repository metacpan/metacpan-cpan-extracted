package Code::TidyAll::Plugin::PerlTidy;

use strict;
use warnings;

use Capture::Tiny qw(capture_merged);
use Perl::Tidy;

use Moo;

extends 'Code::TidyAll::Plugin';

our $VERSION = '0.78';

sub transform_source {
    my ( $self, $source ) = @_;

    # This bit of insanity is needed because if some other code calls
    # Getopt::Long::Configure() to change some options, then everything can go
    # to hell. Internally perltidy() tries to use Getopt::Long without
    # resetting the configuration defaults, leading to very confusing
    # errors. See https://rt.cpan.org/Ticket/Display.html?id=118558
    Getopt::Long::ConfigDefaults();

    # perltidy reports errors in two different ways.
    # Argument/profile errors are output and an error_flag is returned.
    # Syntax errors are sent to errorfile or stderr, depending on the
    # the setting of -se/-nse (aka --standard-error-output).  These flags
    # might be hidden in other bundles, e.g. -pbp.  Be defensive and
    # check both.
    my ( $output, $error_flag, $errorfile, $stderr, $destination );
    $output = capture_merged {
        $error_flag = Perl::Tidy::perltidy(
            argv        => $self->argv,
            source      => \$source,
            destination => \$destination,
            stderr      => \$stderr,
            errorfile   => \$errorfile
        );
    };
    die $stderr          if $stderr;
    die $errorfile       if $errorfile;
    die $output          if $error_flag;
    print STDERR $output if defined($output);
    return $destination;
}

1;

# ABSTRACT: Use perltidy with tidyall

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::PerlTidy - Use perltidy with tidyall

=head1 VERSION

version 0.78

=head1 SYNOPSIS

   # In configuration:

   ; Configure in-line
   ;
   [PerlTidy]
   select = lib/**/*.pm
   argv = --noll

   ; or refer to a .perltidyrc in the same directory
   ;
   [PerlTidy]
   select = lib/**/*.pm
   argv = --profile=$ROOT/.perltidyrc

=head1 DESCRIPTION

Runs L<perltidy>, a Perl tidier.

=head1 INSTALLATION

Install perltidy from CPAN.

    cpanm perltidy

=head1 CONFIGURATION

This plugin accepts the following configuration options:

=head2 argv

Arguments to pass to C<perltidy>.

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
