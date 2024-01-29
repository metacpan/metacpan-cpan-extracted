package Acme::CPANModules::PortedFrom::Ruby;

use strict;
#use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-15'; # DATE
our $DIST = 'Acme-CPANModules-PortedFrom-Ruby'; # DIST
our $VERSION = '0.011'; # VERSION

our $LIST = {
    summary => "List of modules/applications that are ported from (or inspired by) ".
        "Ruby libraries",
    description => <<'_',

If you know of others, please drop me a message.

_
    entries => [
        {
            module => 'App::Sass',
            tags => ['web'],
            #ruby_package => undef,
        },
        {
            module => 'Data::Gimei',
            ruby_package => 'gimei',
            tags => [],
        },
        {
            module => 'Scientist',
            #tags => [],
            #ruby_package => undef,
        },
        {
            module => 'HTTP::Server::Brick',
            tags => ['web'],
            #ruby_package => undef,
        },
        {
            module => 'Plack',
            tags => ['web', 'framework'],
            description => <<'_',

From Plack's documentation: "Plack is like Ruby's Rack or Python's Paste for
WSGI." Plack and PSGI were created by MIYAGAWA in 2009 and were inspired by both
Python's WSGI specification (hence the dual specification-implementation split)
and Ruby's Rack (hence the name).

_
            ruby_package => 'rack',
            ruby_website_url => 'https://rack.github.io/',
            ruby_github_url => 'https://github.com/rack/rack',
        },
        {
            module => 'Squatting',
            tags => ['web', 'framework'],
            ruby_package => 'camping',
            ruby_website_url => 'http://www.ruby-camping.com/',
        },
        {
            module => 'Valiant',
            summary => 'Inspired by the data validation style in Ruby on Rails',
            tags => ['validation', 'framework'],
            ruby_package => 'rails',
            ruby_website_url => 'https://rubyonrails.org/',
        },
        {
            module => 'Dotenv',
            summary => 'Although the 12-factor methodology is not tied to a single language, the original implementation is in Ruby',
            #tags => ['framework'],
            ruby_package => 'dotenv',
            ruby_website_url => 'https://github.com/heroku/12factor',
        },
    ],
};

1;
# ABSTRACT: List of modules/applications that are ported from (or inspired by) Ruby libraries

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PortedFrom::Ruby - List of modules/applications that are ported from (or inspired by) Ruby libraries

=head1 VERSION

This document describes version 0.011 of Acme::CPANModules::PortedFrom::Ruby (from Perl distribution Acme-CPANModules-PortedFrom-Ruby), released on 2024-01-15.

=head1 DESCRIPTION

If you know of others, please drop me a message.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::Sass>

Author: L<WWOLF|https://metacpan.org/author/WWOLF>

=item L<Data::Gimei>

Author: L<YOUPONG|https://metacpan.org/author/YOUPONG>

Ruby project's gem: L<https://rubygems.org/gems/gimei>

=item L<Scientist>

Author: L<LANCEW|https://metacpan.org/author/LANCEW>

=item L<HTTP::Server::Brick>

Author: L<AUFFLICK|https://metacpan.org/author/AUFFLICK>

=item L<Plack>

Author: L<MIYAGAWA|https://metacpan.org/author/MIYAGAWA>

From Plack's documentation: "Plack is like Ruby's Rack or Python's Paste for
WSGI." Plack and PSGI were created by MIYAGAWA in 2009 and were inspired by both
Python's WSGI specification (hence the dual specification-implementation split)
and Ruby's Rack (hence the name).


Ruby project's gem: L<https://rubygems.org/gems/rack>

Ruby project's website: L<https://rack.github.io/>

Ruby project's GitHub: L<https://github.com/rack/rack>

=item L<Squatting>

Author: L<BEPPU|https://metacpan.org/author/BEPPU>

Ruby project's gem: L<https://rubygems.org/gems/camping>

Ruby project's website: L<http://www.ruby-camping.com/>

=item L<Valiant>

Inspired by the data validation style in Ruby on Rails.

Author: L<JJNAPIORK|https://metacpan.org/author/JJNAPIORK>

Ruby project's gem: L<https://rubygems.org/gems/rails>

Ruby project's website: L<https://rubyonrails.org/>

=item L<Dotenv>

Although the 12-factor methodology is not tied to a single language, the original implementation is in Ruby.

Author: L<BOOK|https://metacpan.org/author/BOOK>

Ruby project's gem: L<https://rubygems.org/gems/dotenv>

Ruby project's website: L<https://github.com/heroku/12factor>

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

L<Acme::CPANModules::PortedFrom::Python> and other
C<Acme::CPANModules::PortedFrom::*> modules.

L<Acme::CPANModules::Interop::Ruby> to interact with Ruby things.

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

This software is copyright (c) 2024, 2023, 2022, 2021, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PortedFrom-Ruby>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
