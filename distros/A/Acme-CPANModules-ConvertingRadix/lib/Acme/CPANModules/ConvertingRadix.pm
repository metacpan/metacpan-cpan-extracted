package Acme::CPANModules::ConvertingRadix;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'Acme-CPANModules-ConvertingRadix'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules to convert the radix (base) of a number from one to another',
    entries => [

        {
            module=>'Math::Numseq::RadixConversion',
            description=><<'_',

The list of dependencies seem too much for a simple task: from
<pm:Module::Pluggable> to <pm:File::HomeDir>, <pm:Module::Util>, and so on.
This is because the module is part of the distribution of a large family of
Math::Numseq::* modules.

_
        },

        {
            module=>'Number::AnyBase',
            description=><<'_',

Has one non-core dependency: <pm:Class::Accessor::Faster>.

_
        },

        {
            module=>'Math::NumberBase',
            description=><<'_',

No non-core dependency. The OO interface annoys me slightly.

_
        },

    ],
};

1;
# ABSTRACT: List of modules to convert the radix (base) of a number from one to another

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ConvertingRadix - List of modules to convert the radix (base) of a number from one to another

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::ConvertingRadix (from Perl distribution Acme-CPANModules-ConvertingRadix), released on 2023-08-06.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Math::Numseq::RadixConversion>

The list of dependencies seem too much for a simple task: from
L<Module::Pluggable> to L<File::HomeDir>, L<Module::Util>, and so on.
This is because the module is part of the distribution of a large family of
Math::Numseq::* modules.


=item L<Number::AnyBase>

Author: L<EMAZEP|https://metacpan.org/author/EMAZEP>

Has one non-core dependency: L<Class::Accessor::Faster>.


=item L<Math::NumberBase>

Author: L<YEHEZKIEL|https://metacpan.org/author/YEHEZKIEL>

No non-core dependency. The OO interface annoys me slightly.


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

 % cpanm-cpanmodules -n ConvertingRadix

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries ConvertingRadix | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ConvertingRadix -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::ConvertingRadix -E'say $_->{module} for @{ $Acme::CPANModules::ConvertingRadix::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ConvertingRadix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ConvertingRadix>.

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

This software is copyright (c) 2023, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ConvertingRadix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
