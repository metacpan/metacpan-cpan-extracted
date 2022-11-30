package Module::Features::TextWrapper;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-24'; # DATE
our $DIST = 'Acme-CPANModules-WrappingText'; # DIST
our $VERSION = '0.001'; # VERSION

our %FEATURES_DEF = (
    v => 1,
    summary => 'Features of modules that wrap text',
    description => <<'_',

Keywords: fold

_
    features => {
        can_unicode => {summary => 'Can wrap Unicode text, including wide characters'},
        can_cjk     => {summary => 'Can wrap CJK wide characters'},
        can_ansi    => {summary => 'Can wrap text that contains ANSI color/escape codes'},
    },
);

1;
# ABSTRACT: Features of modules that wrap text

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Features::TextWrapper - Features of modules that wrap text

=head1 VERSION

This document describes version 0.001 of Module::Features::TextWrapper (from Perl distribution Acme-CPANModules-WrappingText), released on 2022-11-24.

=head1 DESCRIPTION

Keywords: fold

=head1 DEFINED FEATURES

Features defined by this module:

=over

=item * can_ansi

Optional. Type: bool. Can wrap text that contains ANSI color/escape codes. 

=item * can_cjk

Optional. Type: bool. Can wrap CJK wide characters. 

=item * can_unicode

Optional. Type: bool. Can wrap Unicode text, including wide characters. 

=back

For more details on module features, see L<Module::Features>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-WrappingText>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-WrappingText>.

=head1 SEE ALSO

L<Module::Features>

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-WrappingText>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
