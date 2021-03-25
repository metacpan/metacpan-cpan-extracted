package Acme::CPANModules::Frameworks;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-03-25'; # DATE
our $DIST = 'Acme-CPANModules-Frameworks'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "List of frameworks on CPAN",
    description => <<'_',

What qualifies as a framewor to be listed here is the existence of ecosystem of
CPAN modules/distributions (plugins, extensions, even application distributions,
etc) pertaining to it.

This list is used in building a list of framework classifiers in
<pm:Module::Features::PerlTrove>.

_
    entries => [
        # app
        {module=>'Jifty', tags=>['category:app']},

        # async
        {module=>'AnyEvent', tags=>['category:async']},
        {module=>'IO::Async', tags=>['category:async']},
        {module=>'POE', tags=>['category:async']},

        # caching
        {module=>'CHI', tags=>['category:caching']},

        # cli
        {module=>'App::Cmd', tags=>['category:cli']},
        {module=>'Perinci::CmdLine', tags=>['category:cli']},

        # database
        {module=>'DBI', tags=>['category:database']},

        # data-dumping
        {module=>'Data::Printer', tags=>['category:data-dumping']},

        # date
        {module=>'DateTime', tags=>['category:date']},

        # distribution-authoring
        {module=>'Dist::Zilla', tags=>['category:distribution-authoring']},
        {module=>'Minilla', tags=>['category:distribution-authoring']},
        {module=>'ShipIt', tags=>['category:distribution-authoring']},

        # e-commerce
        {module=>'Interchange', tags=>['category:e-commerce']},

        # logging
        {module=>'Log::Any', tags=>['category:logging']},
        {module=>'Log::Contextual', tags=>['category:logging']},
        {module=>'Log::Dispatch', tags=>['category:logging']},
        {module=>'Log::ger', tags=>['category:logging']},
        {module=>'Log::Log4perl', tags=>['category:logging']},

        # numeric
        {module=>'PDL', tags=>['category:numeric']},

        # oo
        {module=>'Moose', tags=>['category:oo']},
        {module=>'Moo', tags=>['category:oo']},

        # orm
        {module=>'DBIx::Class', tags=>['category:orm']},

        # template
        {module=>'Template::Toolkit', tags=>['category:template']},

        # testing
        {module=>'Test2', tags=>['category:testing']},

        # type
        {module=>'Specio', tags=>['category:type','category:validation']},
        {module=>'Type::Tiny', tags=>['category:type', 'category:validation']},

        # validation
        {module=>'Params::Validate', tags=>['category:validation']},
        # Params::ValidationCompiler?
        {module=>'Sah', tags=>['category:validation']},
        # Specio*
        # Type::Tiny*

        # web
        {module=>'Catalyst', tags=>['category:web']},
        {module=>'CGI::Application', tags=>['category:web']},
        {module=>'Dancer', tags=>['category:web']},
        {module=>'Dancer2', tags=>['category:web']},
        {module=>'Gantry', tags=>['category:web']},
        {module=>'Mason', tags=>['category:web']},
        {module=>'Maypole', tags=>['category:web']},
        {module=>'Mojolicious', tags=>['category:web']},
        # Plack?

        # web-form
        {module=>'HTML::FormFu', tags=>['category:web-form']},
        {module=>'HTML::FormHandler', tags=>['category:web-form']},
    ],
};

1;
# ABSTRACT: List of frameworks on CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Frameworks - List of frameworks on CPAN

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::Frameworks (from Perl distribution Acme-CPANModules-Frameworks), released on 2021-03-25.

=head1 DESCRIPTION

What qualifies as a framewor to be listed here is the existence of ecosystem of
CPAN modules/distributions (plugins, extensions, even application distributions,
etc) pertaining to it.

This list is used in building a list of framework classifiers in
L<Module::Features::PerlTrove>.

=head1 ACME::MODULES ENTRIES

=over

=item * L<Jifty>

=item * L<AnyEvent>

=item * L<IO::Async>

=item * L<POE>

=item * L<CHI>

=item * L<App::Cmd>

=item * L<Perinci::CmdLine>

=item * L<DBI>

=item * L<Data::Printer>

=item * L<DateTime>

=item * L<Dist::Zilla>

=item * L<Minilla>

=item * L<ShipIt>

=item * L<Interchange>

=item * L<Log::Any>

=item * L<Log::Contextual>

=item * L<Log::Dispatch>

=item * L<Log::ger>

=item * L<Log::Log4perl>

=item * L<PDL>

=item * L<Moose>

=item * L<Moo>

=item * L<DBIx::Class>

=item * L<Template::Toolkit>

=item * L<Test2>

=item * L<Specio>

=item * L<Type::Tiny>

=item * L<Params::Validate>

=item * L<Sah>

=item * L<Catalyst>

=item * L<CGI::Application>

=item * L<Dancer>

=item * L<Dancer2>

=item * L<Gantry>

=item * L<Mason>

=item * L<Maypole>

=item * L<Mojolicious>

=item * L<HTML::FormFu>

=item * L<HTML::FormHandler>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanmodules> CLI (from
L<App::cpanmodules> distribution):

    % cpanmodules ls-entries Frameworks | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Frameworks -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Frameworks -E'say $_->{module} for @{ $Acme::CPANModules::Frameworks::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Frameworks>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Frameworks>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-Frameworks/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
