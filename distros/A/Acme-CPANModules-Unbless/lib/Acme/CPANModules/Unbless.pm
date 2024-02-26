package Acme::CPANModules::Unbless;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-31'; # DATE
our $DIST = 'Acme-CPANModules-Unbless'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules to unbless a reference',
    description => <<'_',

Blessing a reference is easy with `bless()` but surprisingly (or
unsurprisingly?) unblessing a blessed reference is not as simple. Currently you
can use the `unbless()` function from <pm:Data::Structure::Util> or `damn()`
from <pm:Acme::Damn> (which is a slimmer module if you just need unblessing
feature). Both are XS modules. If you need a pure-Perl solution, currently
you're out of luck. <pm:Function::Fallback::CoreOrPP> provides `unbless()` where
the fallback option is shallow copying.

_
    entries => [
        {
            module => 'Data::Structure::Util',
        },
        {
            module => 'Acme::Damn',
        },
        {
            module => 'Function::Fallback::CoreOrPP',
        },
    ],
};

1;
# ABSTRACT: List of modules to unbless a reference

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Unbless - List of modules to unbless a reference

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::Unbless (from Perl distribution Acme-CPANModules-Unbless), released on 2023-10-31.

=head1 DESCRIPTION

Blessing a reference is easy with C<bless()> but surprisingly (or
unsurprisingly?) unblessing a blessed reference is not as simple. Currently you
can use the C<unbless()> function from L<Data::Structure::Util> or C<damn()>
from L<Acme::Damn> (which is a slimmer module if you just need unblessing
feature). Both are XS modules. If you need a pure-Perl solution, currently
you're out of luck. L<Function::Fallback::CoreOrPP> provides C<unbless()> where
the fallback option is shallow copying.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Data::Structure::Util>

Author: L<ANDYA|https://metacpan.org/author/ANDYA>

=item L<Acme::Damn>

Author: L<IBB|https://metacpan.org/author/IBB>

=item L<Function::Fallback::CoreOrPP>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

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

 % cpanm-cpanmodules -n Unbless

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Unbless | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Unbless -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Unbless -E'say $_->{module} for @{ $Acme::CPANModules::Unbless::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Unbless>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Unbless>.

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

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Unbless>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
