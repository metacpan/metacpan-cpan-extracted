package Acme::CPANModules::HaveWebsite;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-16'; # DATE
our $DIST = 'Acme-CPANModules-HaveWebsite'; # DIST
our $VERSION = '0.004'; # VERSION

our $LIST = {
    summary => 'Modules that have their own website',
    description => <<'_',

This list was first constructed based on Gabor Szabo's post:
<https://dev.to/szabgab/perl-modules-with-their-own-web-site-2gmo> on
2021-02-16. It has then been updated with more entries.

_
    entries => [
        {module=>'App::Ack', website_url=>'https://beyondgrep.com/'},
        {module=>'App::cpanminus', website_url=>'http://cpanmin.us/'},
        {module=>'App::perlbrew', website_url=>'https://perlbrew.pl/'},
        {module=>'App::TimeTracker', website_url=>'http://timetracker.plix.at/'},
        {module=>'Catalyst', website_url=>'http://www.catalystframework.org/'},
        {module=>'Dancer', website_url=>'https://perldancer.org/'},
        {module=>'Giblog', website_url=>'https://www.giblog.net/', description=>'Currently in Japanese only'},
        {module=>'Mojolicious', website_url=>'https://mojolicious.org/'},
        {module=>'MooX::Role::JSON_LD', website_url=>'https://davorg.dev/moox-role-json_ld/'},
        {module=>'Padre', website_url=>'http://padre.perlide.org/'},
        {module=>'PDL', website_url=>'https://pdl.perl.org'},
        {module=>'Perl::Critic', website_url=>'http://perlcritic.com/'},
        {module=>'Plack', website_url=>'https://plackperl.org/'},
        {module=>'Rex', website_url=>'https://www.rexify.org/'},
        {module=>'SPVM', website_url=>'https://yuki-kimoto.github.io/spvmdoc-public/', description=>'Currently machine-translated from Japanese'},
        {module=>'Template', website_url=>'http://www.template-toolkit.org/'},
        {module=>'Test::BDD::Cucumber', website_url=>'https://pherkin.pm/'},
        {module=>'Type::Tiny', website_url=>'https://typetiny.toby.ink/'},
        {module=>'Wx', website_url=>'http://www.wxperl.it/'},
        {module=>'Zydeco', website_url=>'https://zydeco.toby.ink/'},
    ],
};

1;
# ABSTRACT: Modules that have their own website

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::HaveWebsite - Modules that have their own website

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::HaveWebsite (from Perl distribution Acme-CPANModules-HaveWebsite), released on 2022-01-16.

=head1 DESCRIPTION

This list was first constructed based on Gabor Szabo's post:
L<https://dev.to/szabgab/perl-modules-with-their-own-web-site-2gmo> on
2021-02-16. It has then been updated with more entries.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::Ack>

Author: L<PETDANCE|https://metacpan.org/author/PETDANCE>

Website URL: L<https://beyondgrep.com/>

=item L<App::cpanminus>

Author: L<MIYAGAWA|https://metacpan.org/author/MIYAGAWA>

Website URL: L<http://cpanmin.us/>

=item L<App::perlbrew>

Author: L<GUGOD|https://metacpan.org/author/GUGOD>

Website URL: L<https://perlbrew.pl/>

=item L<App::TimeTracker>

Author: L<DOMM|https://metacpan.org/author/DOMM>

Website URL: L<http://timetracker.plix.at/>

=item L<Catalyst>

Author: L<HAARG|https://metacpan.org/author/HAARG>

Website URL: L<http://www.catalystframework.org/>

=item L<Dancer>

Author: L<BIGPRESH|https://metacpan.org/author/BIGPRESH>

Website URL: L<https://perldancer.org/>

=item L<Giblog>

Author: L<KIMOTO|https://metacpan.org/author/KIMOTO>

Currently in Japanese only


Website URL: L<https://www.giblog.net/>

=item L<Mojolicious>

Author: L<SRI|https://metacpan.org/author/SRI>

Website URL: L<https://mojolicious.org/>

=item L<MooX::Role::JSON_LD>

Author: L<DAVECROSS|https://metacpan.org/author/DAVECROSS>

Website URL: L<https://davorg.dev/moox-role-json_ld/>

=item L<Padre>

Author: L<PLAVEN|https://metacpan.org/author/PLAVEN>

Website URL: L<http://padre.perlide.org/>

=item L<PDL>

Author: L<ETJ|https://metacpan.org/author/ETJ>

Website URL: L<https://pdl.perl.org>

=item L<Perl::Critic>

Author: L<PETDANCE|https://metacpan.org/author/PETDANCE>

Website URL: L<http://perlcritic.com/>

=item L<Plack>

Author: L<MIYAGAWA|https://metacpan.org/author/MIYAGAWA>

Website URL: L<https://plackperl.org/>

=item L<Rex>

Author: L<FERKI|https://metacpan.org/author/FERKI>

Website URL: L<https://www.rexify.org/>

=item L<SPVM>

Author: L<KIMOTO|https://metacpan.org/author/KIMOTO>

Currently machine-translated from Japanese


Website URL: L<https://yuki-kimoto.github.io/spvmdoc-public/>

=item L<Template>

Author: L<ATOOMIC|https://metacpan.org/author/ATOOMIC>

Website URL: L<http://www.template-toolkit.org/>

=item L<Test::BDD::Cucumber>

Author: L<EHUELS|https://metacpan.org/author/EHUELS>

Website URL: L<https://pherkin.pm/>

=item L<Type::Tiny>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

Website URL: L<https://typetiny.toby.ink/>

=item L<Wx>

Author: L<MDOOTSON|https://metacpan.org/author/MDOOTSON>

Website URL: L<http://www.wxperl.it/>

=item L<Zydeco>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

Website URL: L<https://zydeco.toby.ink/>

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

 % cpanm-cpanmodules -n HaveWebsite

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries HaveWebsite | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=HaveWebsite -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::HaveWebsite -E'say $_->{module} for @{ $Acme::CPANModules::HaveWebsite::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-HaveWebsite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-HaveWebsite>.

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

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-HaveWebsite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
