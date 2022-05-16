## no critic: TestingAndDebugging::RequireUseStrict
package Config::IOD::Constants;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-02'; # DATE
our $DIST = 'Config-IOD'; # DIST
our $VERSION = '0.353'; # VERSION

BEGIN {
    our %constants = (
        COL_TYPE => 0,

        COL_B_RAW => 1,

        COL_D_COMMENT_CHAR => 1,
        COL_D_WS1 => 2,
        COL_D_WS2 => 3,
        COL_D_DIRECTIVE => 4,
        COL_D_WS3 => 5,
        COL_D_ARGS_RAW => 6,
        COL_D_NL => 7,

        COL_C_WS1 => 1,
        COL_C_COMMENT_CHAR => 2,
        COL_C_COMMENT => 3,
        COL_C_NL => 4,

        COL_S_WS1 => 1,
        COL_S_WS2 => 2,
        COL_S_SECTION => 3,
        COL_S_WS3 => 4,
        COL_S_WS4 => 5,
        COL_S_COMMENT_CHAR => 6,
        COL_S_COMMENT => 7,
        COL_S_NL => 8,

        COL_K_WS1 => 1,
        COL_K_KEY => 2,
        COL_K_WS2 => 3,
        COL_K_WS3 => 4,
        COL_K_VALUE_RAW => 5,
        COL_K_NL => 6,
    );
}

use constant \%constants;

use Exporter qw(import);
our @EXPORT_OK = sort keys %constants;
our %EXPORT_TAGS = (ALL => \@EXPORT_OK);

1;
# ABSTRACT: Constants used when parsing IOD document

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::IOD::Constants - Constants used when parsing IOD document

=head1 VERSION

This document describes version 0.353 of Config::IOD::Constants (from Perl distribution Config-IOD), released on 2022-05-02.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Config-IOD>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Config-IOD>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2019, 2017, 2016, 2015, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-IOD>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
