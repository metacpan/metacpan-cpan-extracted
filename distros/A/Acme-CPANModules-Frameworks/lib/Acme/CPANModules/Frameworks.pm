package Acme::CPANModules::Frameworks;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-29'; # DATE
our $DIST = 'Acme-CPANModules-Frameworks'; # DIST
our $VERSION = '0.002'; # VERSION

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
        # acme
        {module=>'Acme::CPANAuthors', tags=>['category:acme']},
        {module=>'Acme::CPANModules', tags=>['category:acme']},

        # app
        {module=>'Jifty', tags=>['category:app']},

        # async
        {module=>'AnyEvent', tags=>['category:async']},
        {module=>'IO::Async', tags=>['category:async']},
        {module=>'POE', tags=>['category:async']},

        # benchmark
        {module=>'Bencher', tags=>['category:benchmark']},

        # caching
        {module=>'CHI', tags=>['category:caching']},

        # cli
        {module=>'App::Cmd', tags=>['category:cli']},
        {module=>'Perinci::CmdLine', tags=>['category:cli']},
        {module=>'ScriptX', tags=>['category:cli','category:web']},

        # data modules
        {module=>'ArrayData', tags=>['category:data']},
        {module=>'HashData', tags=>['category:data']},
        {module=>'Games::Word::Phraselist', tags=>['category:data']},
        {module=>'Games::Word::Wordlist', tags=>['category:data']},
        {module=>'TableData', tags=>['category:data']},
        {module=>'WordList', tags=>['category:data']},

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

        # regexp
        {module=>'Regexp::Common', tags=>['category:regexp']},
        {module=>'Regexp::Pattern', tags=>['category:regexp']},

        # template
        {module=>'Template::Toolkit', tags=>['category:template']},

        # testing
        {module=>'Test2', tags=>['category:testing']},

        # type
        {module=>'Specio', tags=>['category:type','category:validation']},
        {module=>'Type::Tiny', tags=>['category:type', 'category:validation']},

        # validation
        {module=>'Data::Sah', tags=>['category:validation']},
        {module=>'Params::Validate', tags=>['category:validation']},
        # Params::ValidationCompiler?
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

This document describes version 0.002 of Acme::CPANModules::Frameworks (from Perl distribution Acme-CPANModules-Frameworks), released on 2022-11-29.

=head1 DESCRIPTION

What qualifies as a framewor to be listed here is the existence of ecosystem of
CPAN modules/distributions (plugins, extensions, even application distributions,
etc) pertaining to it.

This list is used in building a list of framework classifiers in
L<Module::Features::PerlTrove>.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Acme::CPANAuthors>

Author: L<ISHIGAKI|https://metacpan.org/author/ISHIGAKI>

=item L<Acme::CPANModules>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Jifty>

Author: L<ALEXMV|https://metacpan.org/author/ALEXMV>

=item L<AnyEvent>

Author: L<MLEHMANN|https://metacpan.org/author/MLEHMANN>

=item L<IO::Async>

Author: L<PEVANS|https://metacpan.org/author/PEVANS>

=item L<POE>

Author: L<BINGOS|https://metacpan.org/author/BINGOS>

=item L<Bencher>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<CHI>

Author: L<ASB|https://metacpan.org/author/ASB>

=item L<App::Cmd>

Author: L<RJBS|https://metacpan.org/author/RJBS>

=item L<Perinci::CmdLine>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<ScriptX>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<ArrayData>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<HashData>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Games::Word::Phraselist>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Games::Word::Wordlist>

Author: L<DOY|https://metacpan.org/author/DOY>

=item L<TableData>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<WordList>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<DBI>

Author: L<TIMB|https://metacpan.org/author/TIMB>

=item L<Data::Printer>

Author: L<GARU|https://metacpan.org/author/GARU>

=item L<DateTime>

Author: L<DROLSKY|https://metacpan.org/author/DROLSKY>

=item L<Dist::Zilla>

Author: L<RJBS|https://metacpan.org/author/RJBS>

=item L<Minilla>

Author: L<SYOHEX|https://metacpan.org/author/SYOHEX>

=item L<ShipIt>

Author: L<MIYAGAWA|https://metacpan.org/author/MIYAGAWA>

=item L<Interchange>

=item L<Log::Any>

Author: L<PREACTION|https://metacpan.org/author/PREACTION>

=item L<Log::Contextual>

Author: L<FREW|https://metacpan.org/author/FREW>

=item L<Log::Dispatch>

Author: L<DROLSKY|https://metacpan.org/author/DROLSKY>

=item L<Log::ger>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Log::Log4perl>

Author: L<ETJ|https://metacpan.org/author/ETJ>

=item L<PDL>

Author: L<ETJ|https://metacpan.org/author/ETJ>

=item L<Moose>

Author: L<ETHER|https://metacpan.org/author/ETHER>

=item L<Moo>

Author: L<HAARG|https://metacpan.org/author/HAARG>

=item L<DBIx::Class>

Author: L<RIBASUSHI|https://metacpan.org/author/RIBASUSHI>

=item L<Regexp::Common>

Author: L<ABIGAIL|https://metacpan.org/author/ABIGAIL>

=item L<Regexp::Pattern>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Template::Toolkit>

Author: L<ABW|https://metacpan.org/author/ABW>

=item L<Test2>

Author: L<EXODIST|https://metacpan.org/author/EXODIST>

=item L<Specio>

Author: L<DROLSKY|https://metacpan.org/author/DROLSKY>

=item L<Type::Tiny>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

=item L<Data::Sah>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Params::Validate>

Author: L<DROLSKY|https://metacpan.org/author/DROLSKY>

=item L<Catalyst>

Author: L<JJNAPIORK|https://metacpan.org/author/JJNAPIORK>

=item L<CGI::Application>

Author: L<MARTO|https://metacpan.org/author/MARTO>

=item L<Dancer>

Author: L<BIGPRESH|https://metacpan.org/author/BIGPRESH>

=item L<Dancer2>

Author: L<CROMEDOME|https://metacpan.org/author/CROMEDOME>

=item L<Gantry>

Author: L<TKEEFER|https://metacpan.org/author/TKEEFER>

=item L<Mason>

Author: L<JSWARTZ|https://metacpan.org/author/JSWARTZ>

=item L<Maypole>

Author: L<TEEJAY|https://metacpan.org/author/TEEJAY>

=item L<Mojolicious>

Author: L<SRI|https://metacpan.org/author/SRI>

=item L<HTML::FormFu>

Author: L<CFRANKS|https://metacpan.org/author/CFRANKS>

=item L<HTML::FormHandler>

Author: L<GSHANK|https://metacpan.org/author/GSHANK>

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

 % cpanm-cpanmodules -n Frameworks

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Frameworks | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Frameworks -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Frameworks -E'say $_->{module} for @{ $Acme::CPANModules::Frameworks::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Frameworks>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Frameworks>.

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

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Frameworks>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
