package Acme::CPANModules::OneLetter;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-OneLetter'; # DIST
our $VERSION = '0.004'; # VERSION

our $LIST = {
    summary => 'List of one-letter CPAN modules',
    description => <<'_',

Just a list of one-letter modules on CPAN.

To produce this list, you can also use <prog:lcpan>:

    % lcpan mods -l -x --or `perl -E'say for "A".."Z","a".."z","_"'`

For CPAN author, What one-letter name can I use that's available? (Requires
<prog:setop> and <prog:cpanmodules> CLIs.)

    % setop --diff <(perl -E'say for "A".."Z","a".."z","_"') <(cpanmodules ls-entries OneLetter)

_
    entries => [
        {module=>'B'},
        {module=>'D'},
        {module=>'H'},
        {module=>'K'},
        {module=>'L'},
        {module=>'M'},
        {module=>'O'},
        {module=>'P'},
        {module=>'T'},
        {module=>'U'},
        {module=>'V'},
        {module=>'Z'},
        {module=>'c'},
    ],
};

1;
# ABSTRACT: List of one-letter CPAN modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::OneLetter - List of one-letter CPAN modules

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::OneLetter (from Perl distribution Acme-CPANModules-OneLetter), released on 2023-10-29.

=head1 DESCRIPTION

Just a list of one-letter modules on CPAN.

To produce this list, you can also use L<lcpan>:

 % lcpan mods -l -x --or C<perl -E'say for "A".."Z","a".."z","_"'>

For CPAN author, What one-letter name can I use that's available? (Requires
L<setop> and L<cpanmodules> CLIs.)

 % setop --diff <(perl -E'say for "A".."Z","a".."z","_"') <(cpanmodules ls-entries OneLetter)

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<B>

Author: L<RJBS|https://metacpan.org/author/RJBS>

=item L<D>

Author: L<YOITO|https://metacpan.org/author/YOITO>

=item L<H>

Author: L<EXODIST|https://metacpan.org/author/EXODIST>

=item L<K>

Author: L<WHITNEY|https://metacpan.org/author/WHITNEY>

=item L<L>

Author: L<SONGMU|https://metacpan.org/author/SONGMU>

=item L<M>

Author: L<MSTROUT|https://metacpan.org/author/MSTROUT>

=item L<O>

Author: L<RJBS|https://metacpan.org/author/RJBS>

=item L<P>

Author: L<LAWALSH|https://metacpan.org/author/LAWALSH>

=item L<T>

Author: L<EXODIST|https://metacpan.org/author/EXODIST>

=item L<U>

Author: L<DAGOLDEN|https://metacpan.org/author/DAGOLDEN>

=item L<V>

Author: L<ABELTJE|https://metacpan.org/author/ABELTJE>

=item L<Z>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

=item L<c>

Author: L<JROCKWAY|https://metacpan.org/author/JROCKWAY>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n OneLetter

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries OneLetter | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=OneLetter -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::OneLetter -E'say $_->{module} for @{ $Acme::CPANModules::OneLetter::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-OneLetter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-OneLetter>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

This software is copyright (c) 2023, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-OneLetter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
