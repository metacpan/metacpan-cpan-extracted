package Acme::CPANModules::HaveWebsite;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-06'; # DATE
our $DIST = 'Acme-CPANModules-HaveWebsite'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;

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

This document describes version 0.003 of Acme::CPANModules::HaveWebsite (from Perl distribution Acme-CPANModules-HaveWebsite), released on 2021-05-06.

=head1 DESCRIPTION

This list was first constructed based on Gabor Szabo's post:
L<https://dev.to/szabgab/perl-modules-with-their-own-web-site-2gmo> on
2021-02-16. It has then been updated with more entries.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<App::Ack>

Website URL: L<https://beyondgrep.com/>

=item * L<App::cpanminus>

Website URL: L<http://cpanmin.us/>

=item * L<App::perlbrew>

Website URL: L<https://perlbrew.pl/>

=item * L<App::TimeTracker>

Website URL: L<http://timetracker.plix.at/>

=item * L<Catalyst>

Website URL: L<http://www.catalystframework.org/>

=item * L<Dancer>

Website URL: L<https://perldancer.org/>

=item * L<Giblog>

Website URL: L<https://www.giblog.net/>

=item * L<Mojolicious>

Website URL: L<https://mojolicious.org/>

=item * L<MooX::Role::JSON_LD>

Website URL: L<https://davorg.dev/moox-role-json_ld/>

=item * L<Padre>

Website URL: L<http://padre.perlide.org/>

=item * L<PDL>

Website URL: L<https://pdl.perl.org>

=item * L<Perl::Critic>

Website URL: L<http://perlcritic.com/>

=item * L<Plack>

Website URL: L<https://plackperl.org/>

=item * L<Rex>

Website URL: L<https://www.rexify.org/>

=item * L<SPVM>

Website URL: L<https://yuki-kimoto.github.io/spvmdoc-public/>

=item * L<Template>

Website URL: L<http://www.template-toolkit.org/>

=item * L<Test::BDD::Cucumber>

Website URL: L<https://pherkin.pm/>

=item * L<Type::Tiny>

Website URL: L<https://typetiny.toby.ink/>

=item * L<Wx>

Website URL: L<http://www.wxperl.it/>

=item * L<Zydeco>

Website URL: L<https://zydeco.toby.ink/>

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

    % cpanmodules ls-entries HaveWebsite | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=HaveWebsite -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::HaveWebsite -E'say $_->{module} for @{ $Acme::CPANModules::HaveWebsite::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-HaveWebsite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-HaveWebsite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-HaveWebsite/issues>

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
