package Acme::CPANModules::PortedFrom::Ruby;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-04'; # DATE
our $DIST = 'Acme-CPANModules-PortedFrom-Ruby'; # DIST
our $VERSION = '0.008'; # VERSION

our $LIST = {
    summary => "Modules/applications that are ported from (or inspired by) ".
        "Ruby libraries",
    description => <<'_',

If you know of others, please drop me a message.

_
    entries => [
        {
            module => 'App::Sass',
            #ruby_package => undef',
            tags => ['web'],
        },
        {
            module => 'Data::Gimei',
            ruby_package => 'gimei',
            tags => [],
        },
        {
            module => 'Scientist',
            #ruby_package => undef',
            #tags => [''],
        },
        {
            module => 'HTTP::Server::Brick',
            #ruby_package => undef',
            tags => ['web'],
        },
        {
            module => 'Plack',
            ruby_package => 'rack',
            tags => ['web'],
            description => <<'_',

From Plack's documentation: "Plack is like Ruby's Rack or Python's Paste for
WSGI." Plack and PSGI were created by MIYAGAWA in 2009 and were inspired by both
Python's WSGI specification (hence the dual specification-implementation split)
and Ruby's Rack (hence the name).

_
        },
    ],
};

1;
# ABSTRACT: Modules/applications that are ported from (or inspired by) Ruby libraries

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PortedFrom::Ruby - Modules/applications that are ported from (or inspired by) Ruby libraries

=head1 VERSION

This document describes version 0.008 of Acme::CPANModules::PortedFrom::Ruby (from Perl distribution Acme-CPANModules-PortedFrom-Ruby), released on 2022-06-04.

=head1 DESCRIPTION

=head2 SEE ALSO

L<Acme::CPANModules::PortedFrom::Python> and other
C<Acme::CPANModules::PortedFrom::*> modules.

If you know of others, please drop me a message.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<App::Sass> - sass command-line tool modeled after the ruby's version

Author: L<WWOLF|https://metacpan.org/author/WWOLF>

=item * L<Data::Gimei> - a Perl port of Ruby's gimei generates fake data in Japanese.

Author: L<YOUPONG|https://metacpan.org/author/YOUPONG>

=item * L<Scientist>

Author: L<LANCEW|https://metacpan.org/author/LANCEW>

=item * L<HTTP::Server::Brick> - Simple pure perl http server for prototyping "in the style of" Ruby's WEBrick

Author: L<AUFFLICK|https://metacpan.org/author/AUFFLICK>

=item * L<Plack> - Perl Superglue for Web frameworks and Web Servers (PSGI toolkit)

Author: L<MIYAGAWA|https://metacpan.org/author/MIYAGAWA>

From Plack's documentation: "Plack is like Ruby's Rack or Python's Paste for
WSGI." Plack and PSGI were created by MIYAGAWA in 2009 and were inspired by both
Python's WSGI specification (hence the dual specification-implementation split)
and Ruby's Rack (hence the name).


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

 % cpanm-cpanmodules -n PortedFrom::Ruby

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries PortedFrom::Ruby | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PortedFrom::Ruby -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PortedFrom::Ruby -E'say $_->{module} for @{ $Acme::CPANModules::PortedFrom::Ruby::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PortedFrom-Ruby>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PortedFrom-Ruby>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PortedFrom-Ruby>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
