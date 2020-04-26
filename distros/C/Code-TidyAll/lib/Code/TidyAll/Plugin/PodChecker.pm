package Code::TidyAll::Plugin::PodChecker;

use strict;
use warnings;

use Pod::Checker;
use Specio::Library::Numeric;

use Moo;

extends 'Code::TidyAll::Plugin';

our $VERSION = '0.78';

has warnings => (
    is  => 'ro',
    isa => t('PositiveInt'),
);

sub validate_file {
    my ( $self, $file ) = @_;

    my $result;
    my %options = ( $self->warnings ? ( '-warnings' => $self->warnings ) : () );
    my $checker = Pod::Checker->new(%options);
    my $output;
    open my $fh, '>', \$output;
    $checker->parse_from_file( $file->stringify, $fh );
    die $output
        if $checker->num_errors > 0
        || ( $self->warnings && $checker->num_warnings > 0 );
}

1;

# ABSTRACT: Use podchecker with tidyall

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::PodChecker - Use podchecker with tidyall

=head1 VERSION

version 0.78

=head1 SYNOPSIS

   In configuration:

   ; Check for errors, but ignore warnings
   ;
   [PodChecker]
   select = lib/**/*.{pm,pod}

   ; Die on level 1 warnings (can also be set to 2)
   ;
   [PodChecker]
   select = lib/**/*.{pm,pod}
   warnings = 1

=head1 DESCRIPTION

Runs L<podchecker>, a POD validator, and dies if any problems were found.

=head1 INSTALLATION

Install podchecker from CPAN.

    cpanm podchecker

=head1 CONFIGURATION

This plugin accepts the following configuration options:

=head2 warnings

The level of warnings to consider as errors - 1 or 2. By default, warnings will
be ignored.

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
