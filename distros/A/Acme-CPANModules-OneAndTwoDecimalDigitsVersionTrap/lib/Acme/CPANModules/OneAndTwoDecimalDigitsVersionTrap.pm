package Acme::CPANModules::OneAndTwoDecimalDigitsVersionTrap;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-OneAndTwoDecimalDigitsVersionTrap'; # DIST
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => 'List of CPAN distributions which have been trapped by the one- and two decimal digits versioning scheme',
    description => <<'_',

The x.y and x.yy versioning scheme used in Perl distribution has a trap: when
you release a new version by incrementing the patchlevel part into x.y.z and
x.yy.z, the new version number will be *less* than x.y and x.yy because x.y and
x.yy will numify to x.y00 and x.yy0 respectivey; while x.y.z and x.yy.z will
numify to x.00y.z and x.0yy, respectively.

So if you release Acme-MyDist-0.1 (numifies to 0.100000) then Acme-MyDist-0.1.1
(0.001001), or Acme-MyDist-0.01 (0.010000) then Acme-MyDist-0.01.1 (0.001001),
PAUSE will *refuse* to index your new version because of "decreasing version
number."

This does *not* happen when you release Acme-MyDist-0.001 (0.001000) and then
Acme-MyDist-0.001.1 (0.001001).

This thing is peculiar to Perl, and is not intuitive. Consequently, sometimes
CPAN authors are not familiar with this and thus have fallen into this trap.

This list chronicles distributions which have been trapped by this.

For a bit more details, see
<https://perlancar.wordpress.com/2018/09/10/should-i-choose-x-yy-or-x-yyy-versioning-scheme-for-my-perl-module/>
and also <pm:version>.

_
    entries => [
        # sorted by time, from most recent

        {
            module=>"Validate::Simple",
            summary=>"From 0.01 to 0.01.1",
            date=>"2020-01-01",
            author=>"ANDREIP",
            description=><<'_',

Author's comment in ChangeLog: "Change version properly."

_
        },

        {
            module=>"Bencher",
            summary=>"From 0.46 to 0.46.1",
            date=>"2016-03-31",
            author=>"PERLANCAR",
            description=><<'_',

Author's comment in ChangeLog: "This version number is broken because 0.46 >
0.46.1 because 0.46 normalizes to 0.460.000 while 0.46.1 is 0.046.100. This has
happened a few times to me in other distributions too, so perhaps it's time to
consider switching to a 3-digit minor version."

Author's blog post:
<https://perlancar.wordpress.com/2018/09/10/should-i-choose-x-yy-or-x-yyy-versioning-scheme-for-my-perl-module/>
(2016-09-10).

_
        },

        {
            module=>"Array::Compare",
            summary=>"From 2.12 to 2.12.1",
            date=>"2016-12-08",
            author=>"DAVECROSS",
            description=><<'_',

Author's comment in ChangeLog: "Fixing the idiocy in the previous version."

Author's blog post: <https://perlhacks.com/2016/12/version-numbers/>
(2016-12-13).

_
        },

        {
            module=>"Acme::CPANLists",
            summary=>"From 0.02 to 0.9.0",
            date=>"2015-10-23",
            author=>"PERLANCAR",
            description=><<'_',

Author's comment in ChangeLog: "Update version number so it's higher than 0.02
(d'oh)."

_
        },
    ],
};

1;
# ABSTRACT: List of CPAN distributions which have been trapped by the one- and two decimal digits versioning scheme

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::OneAndTwoDecimalDigitsVersionTrap - List of CPAN distributions which have been trapped by the one- and two decimal digits versioning scheme

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::OneAndTwoDecimalDigitsVersionTrap (from Perl distribution Acme-CPANModules-OneAndTwoDecimalDigitsVersionTrap), released on 2023-10-29.

=head1 DESCRIPTION

The x.y and x.yy versioning scheme used in Perl distribution has a trap: when
you release a new version by incrementing the patchlevel part into x.y.z and
x.yy.z, the new version number will be I<less> than x.y and x.yy because x.y and
x.yy will numify to x.y00 and x.yy0 respectivey; while x.y.z and x.yy.z will
numify to x.00y.z and x.0yy, respectively.

So if you release Acme-MyDist-0.1 (numifies to 0.100000) then Acme-MyDist-0.1.1
(0.001001), or Acme-MyDist-0.01 (0.010000) then Acme-MyDist-0.01.1 (0.001001),
PAUSE will I<refuse> to index your new version because of "decreasing version
number."

This does I<not> happen when you release Acme-MyDist-0.001 (0.001000) and then
Acme-MyDist-0.001.1 (0.001001).

This thing is peculiar to Perl, and is not intuitive. Consequently, sometimes
CPAN authors are not familiar with this and thus have fallen into this trap.

This list chronicles distributions which have been trapped by this.

For a bit more details, see
L<https://perlancar.wordpress.com/2018/09/10/should-i-choose-x-yy-or-x-yyy-versioning-scheme-for-my-perl-module/>
and also L<version>.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Validate::Simple>

From 0.01 to 0.01.1.

Author: L<ANDREIP|https://metacpan.org/author/ANDREIP>

Author's comment in ChangeLog: "Change version properly."


=item L<Bencher>

From 0.46 to 0.46.1.

Author's comment in ChangeLog: "This version number is broken because 0.46 >
0.46.1 because 0.46 normalizes to 0.460.000 while 0.46.1 is 0.046.100. This has
happened a few times to me in other distributions too, so perhaps it's time to
consider switching to a 3-digit minor version."

Author's blog post:
L<https://perlancar.wordpress.com/2018/09/10/should-i-choose-x-yy-or-x-yyy-versioning-scheme-for-my-perl-module/>
(2016-09-10).


=item L<Array::Compare>

From 2.12 to 2.12.1.

Author: L<DAVECROSS|https://metacpan.org/author/DAVECROSS>

Author's comment in ChangeLog: "Fixing the idiocy in the previous version."

Author's blog post: L<https://perlhacks.com/2016/12/version-numbers/>
(2016-12-13).


=item L<Acme::CPANLists>

From 0.02 to 0.9.0.

Author's comment in ChangeLog: "Update version number so it's higher than 0.02
(d'oh)."


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

 % cpanm-cpanmodules -n OneAndTwoDecimalDigitsVersionTrap

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries OneAndTwoDecimalDigitsVersionTrap | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=OneAndTwoDecimalDigitsVersionTrap -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::OneAndTwoDecimalDigitsVersionTrap -E'say $_->{module} for @{ $Acme::CPANModules::OneAndTwoDecimalDigitsVersionTrap::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-OneAndTwoDecimalDigitsVersionTrap>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-OneAndTwoDecimalDigitsVersionTrap>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-OneAndTwoDecimalDigitsVersionTrap>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
