package Code::TidyAll::Plugin::PHPCodeSniffer;

use strict;
use warnings;

use IPC::Run3;

use Moo;

extends 'Code::TidyAll::Plugin';

our $VERSION = '0.61';

sub _build_cmd {'phpcs'}

sub validate_file {
    my ( $self, $file ) = @_;

    my @cmd = ( $self->cmd, $self->argv, $file );
    my $output;
    run3( \@cmd, \undef, \$output, \$output );
    if ( $? > 0 ) {
        $output ||= 'problem running ' . $self->cmd;
        die "$output\n";
    }
}

1;

# ABSTRACT: Use phpcs with tidyall

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::PHPCodeSniffer - Use phpcs with tidyall

=head1 VERSION

version 0.61

=head1 SYNOPSIS

   In configuration:

   [PHPCodeSniffer]
   select = htdocs/**/*.{php,js,css}
   cmd = /usr/local/pear/bin/phpcs
   argv = --severity 4

=head1 DESCRIPTION

Runs L<phpcs|http://pear.php.net/package/PHP_CodeSniffer> which analyzes PHP,
JavaScript and CSS files and detects violations of a defined set of coding
standards.

=head1 INSTALLATION

Install L<PEAR|http://pear.php.net/>, then install C<phpcs> from PEAR:

    pear install PHP_CodeSniffer

=head1 CONFIGURATION

=over

=item argv

Arguments to pass to C<phpcs>

=item cmd

Full path to C<phpcs>

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
