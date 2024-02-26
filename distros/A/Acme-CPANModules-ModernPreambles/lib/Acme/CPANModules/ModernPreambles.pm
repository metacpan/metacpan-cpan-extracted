package Acme::CPANModules::ModernPreambles;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-ModernPreambles'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules that offer modern preambles',
    description => <<'_',

The overwhelming convention for coding Perl properly code is to at least add the
following preamble:

    use strict;
    use warnings;

to the beginning of your code. But some people say that's not enough, and they
develop modules/pragmas that bundle the above incantation plus some additional
stuffs. For example:

    use Modern::Perl '2018';

is equivalent to:

    use strict;
    use warnings;
    use feature ':5.26';
    mro::set_mro( scalar caller(), 'c3' );

I think <pm:Modern::Perl> is one of the first to popularize this modern preamble
concept and a bunch of similar preambles emerged. This list catalogs them.

Meanwhile, you can also use:

    use v5.12; # enables strict and warnings, as well as all 5.12 features (see <pm:feature> for more details on new features of each perl release)

and so on, but this also means you set a minimum Perl version.

_
    entries => [
        {module=>'Alt::common::sense::TOBYINK'},
        {module=>'common::sense'},
        {module=>'latest'},
        {module=>'Modern::Perl'},
        {module=>'nonsense'},
        {module=>'perl5'},
        {module=>'perl5i'},
    ],
};

1;
# ABSTRACT: List of modules that offer modern preambles

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ModernPreambles - List of modules that offer modern preambles

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::ModernPreambles (from Perl distribution Acme-CPANModules-ModernPreambles), released on 2023-10-29.

=head1 DESCRIPTION

The overwhelming convention for coding Perl properly code is to at least add the
following preamble:

 use strict;
 use warnings;

to the beginning of your code. But some people say that's not enough, and they
develop modules/pragmas that bundle the above incantation plus some additional
stuffs. For example:

 use Modern::Perl '2018';

is equivalent to:

 use strict;
 use warnings;
 use feature ':5.26';
 mro::set_mro( scalar caller(), 'c3' );

I think L<Modern::Perl> is one of the first to popularize this modern preamble
concept and a bunch of similar preambles emerged. This list catalogs them.

Meanwhile, you can also use:

 use v5.12; # enables strict and warnings, as well as all 5.12 features (see L<feature> for more details on new features of each perl release)

and so on, but this also means you set a minimum Perl version.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Alt::common::sense::TOBYINK>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

=item L<common::sense>

Author: L<MLEHMANN|https://metacpan.org/author/MLEHMANN>

=item L<latest>

Author: L<ANDYA|https://metacpan.org/author/ANDYA>

=item L<Modern::Perl>

Author: L<CHROMATIC|https://metacpan.org/author/CHROMATIC>

=item L<nonsense>

Author: L<JROCKWAY|https://metacpan.org/author/JROCKWAY>

=item L<perl5>

Author: L<INGY|https://metacpan.org/author/INGY>

=item L<perl5i>

Author: L<MSCHWERN|https://metacpan.org/author/MSCHWERN>

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

 % cpanm-cpanmodules -n ModernPreambles

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries ModernPreambles | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ModernPreambles -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::ModernPreambles -E'say $_->{module} for @{ $Acme::CPANModules::ModernPreambles::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ModernPreambles>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ModernPreambles>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ModernPreambles>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
