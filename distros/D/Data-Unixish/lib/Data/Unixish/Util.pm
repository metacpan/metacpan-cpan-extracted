package Data::Unixish::Util;

use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-02-24'; # DATE
our $DIST = 'Data-Unixish'; # DIST
our $VERSION = '1.574'; # VERSION

our @EXPORT_OK = qw(%common_args filter_args);

our %common_args = (
    in  => {
        summary => 'Input stream (e.g. array or filehandle)',
        schema  => ['array'],
        #cmdline_src => 'stdin_or_files', # not until pericmd-base supports streaming
        #stream => 1,
    },
    out => {
        summary => 'Output stream (e.g. array or filehandle)',
        schema  => 'any', # TODO: any* => of => [stream*, array*]
        #req => 1,
    },
);

sub filter_args {
    my $hash = shift;
    return { map {$_=>$hash->{$_}} grep {/\A\w+\z/} keys %$hash };
}

1;
# ABSTRACT: Utility routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::Util - Utility routines

=head1 VERSION

This document describes version 1.574 of Data::Unixish::Util (from Perl distribution Data-Unixish), released on 2025-02-24.

=head1 EXPORTS

C<%common_args>

=head1 FUNCTIONS

=head2 filter_args

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
