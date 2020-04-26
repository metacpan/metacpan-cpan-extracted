package Code::TidyAll::Plugin::PodTidy;

use strict;
use warnings;

use Capture::Tiny qw(capture_merged);
use Pod::Tidy;
use Specio::Library::Numeric;

use Moo;

extends 'Code::TidyAll::Plugin';

our $VERSION = '0.78';

has columns => (
    is  => 'ro',
    isa => t('PositiveInt'),
);

sub transform_file {
    my ( $self, $file ) = @_;

    my $output = capture_merged {
        Pod::Tidy::tidy_files(
            files    => [ $file->stringify ],
            inplace  => 1,
            nobackup => 1,
            verbose  => 1,
            ( $self->columns ? ( columns => $self->columns ) : () ),
        );
    };
    die $output if $output =~ /\S/ && $output !~ /does not contain Pod/;
}

1;

# ABSTRACT: Use podtidy with tidyall

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::PodTidy - Use podtidy with tidyall

=head1 VERSION

version 0.78

=head1 SYNOPSIS

   In configuration:

   [PodTidy]
   select = lib/**/*.{pm,pod}
   columns = 90

=head1 DESCRIPTION

Runs L<podtidy>, which will tidy the POD in your Perl or POD-only file.

=head1 INSTALLATION

Install podtidy from CPAN.

    cpanm podtidy

=head1 CONFIGURATION

This plugin accepts the following configuration options:

=head2 columns

Number of columns per line.

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
