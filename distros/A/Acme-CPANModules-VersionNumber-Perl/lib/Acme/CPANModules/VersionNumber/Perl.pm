package Acme::CPANModules::VersionNumber::Perl;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-31'; # DATE
our $DIST = 'Acme-CPANModules-VersionNumber-Perl'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of libraries for working with Perl version numbers (or version strings)',
    description => <<'_',

The core module <pm:version> (a.k.a. version.pm) should be your first go-to
module when dealing with Perl version numbers. Other modules can also help in
some aspects. Modules mentioned here include: <pm:Perl::Version>,
<pm:Versioning::Scheme::Perl>.

## Version numbers in Perl

There are two styles of version numbers used in the Perl world (i.e. for the
versioning of perl interpreter itself and for versioning Perl modules): decimal
(x.y) or dotted decimals (x.y.z or even more parts; the "v" prefix forces dotted
decimal to avoid ambiguity when there is only a single dot, e.g. v1.2).

The former variant offers simplicity since version number can mostly be
represented by a floating point number (quoting as string is still recommended
to retain all precision and trailing zeros) and comparing versions can be done
numerically. However they are often very limited so in those cases a dotted
decimal variant can be used. For example the perl interpreter itself uses x.y.z
convention.

Dotted decimal can be converted to decimal ("numified") form using this
convention: minor and lesser parts are given (at least) three decimal digits
each. For example, 1.2.3 becomes 1.002003. 1.20.3 becomes 1.020003. This can
give some surprise which has bitten Perl programmers, novice and expert alike.
In fact, it is the major gotcha when dealing with version numbers in Perl. For
example '0.02' (a decimal form) numifies to 0.02, but 'v0.02' (a dotted decimal
form) numifies to 0.002. Hence, v0.02 is less than 0.02 or even 0.01 when
compared using version->parse(). Another gotcha is when a module author decides
to go from 0.02 to 0.2.1 or 0.02.1. 0.02 (a decimal form) numifies to 0.02 while
0.2.1 or 0.02.1 (dotted decimal) numifies to 0.002001. Hence, going from 0.02 to
0.02.1 will actually *decrease* your version number. I recommend using x.yyy if
you use decimal form, i.e. start from 0.001 and not 0.01. It will support you
going smoothly to dotted decimal if you decide to do it one day.

The numification is also problematic when a number part is > 999, e.g. 1.2.1234.
This breaks version comparison when comparison is done with version->parse().

Aside from the abovementioned two styles, there is another: CPAN
distributions/modules can add an underscore in the last part of the version
number to signify alpha/dev/trial release, e.g. 1.2.3_01. PAUSE will not index
such releases, so testers will need to specify an explicit version number to
install, e.g. `cpanm Foo@1.2.3_01`. In some cases you need to pay attention when
comparing this kind of version numbers.

## Checking if a string is a valid version number

To check if a string is a valid Perl version number, you can do:

    version->parse($str)

which will die if C<$str> contains an invalid version string. version.pm can
handle the "v" prefix, (e.g. "v1.2"), dotted-decimal (e.g. "1.2.3" but also
"1.2.3.4.5"), as well as alpha/dev/trial part (e.g. "v1.1.1_001").

## Parsing a version number

version->parse, obviously enough, is used to parse a version number string into
a structure:

    use Data::Dump;
    dd( version->parse("1.2.3") );

which prints:

    bless({ original => "1.2.3", qv => 1, version => [1, 2, 3] }, "version")

However:

    dd( version->parse("1.2.3_01") );

prints:

    bless({ alpha => 1, original => "1.2.3_01", qv => 1, version => [1, 2, 301] }, "version")

## Comparing version numbers

You can compare two version numbers again using version->parse():

    version->parse($str1) <=> version->parse($str2)

For example:

    version->parse("1.2.3") <=> version->parse("v1.3.0");  # => -1

Be careful when dealing with alpha/dev/trial version:

    version->parse("1.2.3_01") <=> version->parse("v1.2.4")  ;  # => 1
    version->parse("1.2.3_01") <=> version->parse("v1.2.301");  # => 0
    version->parse("1.2.3_01") <=> version->parse("v1.2.400");  # => -1

## Normalizing a version number

To normalize a version number:

    version->parse($str)->normal

This will add a "v" prefix, force a dotted decimal form, and remove insignifcant
zeros. Examples:

    version->parse(1.2)      ->normal; # => "v1.200.0"
    version->parse("1.2.3")  ->normal; # => "v1.2.3"
    version->parse("1.2.30") ->normal; # => "v1.2.30"
    version->parse("1.2.030")->normal; # => "v1.2.30"

## Incrementing a version number

Some modules like <pm:Perl::Version> and <pm:Versioning::Scheme::Perl> can help
increase version numbers (or whichever part of the number). The last one can
also decrement parts.

_
    entries => [
        {module=>'version'},
        {module=>'Perl::Version'},
        {module=>'Versioning::Scheme::Perl'},
    ],
};

1;
# ABSTRACT: List of libraries for working with Perl version numbers (or version strings)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::VersionNumber::Perl - List of libraries for working with Perl version numbers (or version strings)

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::VersionNumber::Perl (from Perl distribution Acme-CPANModules-VersionNumber-Perl), released on 2023-10-31.

=head1 DESCRIPTION

The core module L<version> (a.k.a. version.pm) should be your first go-to
module when dealing with Perl version numbers. Other modules can also help in
some aspects. Modules mentioned here include: L<Perl::Version>,
L<Versioning::Scheme::Perl>.

=head2 Version numbers in Perl

There are two styles of version numbers used in the Perl world (i.e. for the
versioning of perl interpreter itself and for versioning Perl modules): decimal
(x.y) or dotted decimals (x.y.z or even more parts; the "v" prefix forces dotted
decimal to avoid ambiguity when there is only a single dot, e.g. v1.2).

The former variant offers simplicity since version number can mostly be
represented by a floating point number (quoting as string is still recommended
to retain all precision and trailing zeros) and comparing versions can be done
numerically. However they are often very limited so in those cases a dotted
decimal variant can be used. For example the perl interpreter itself uses x.y.z
convention.

Dotted decimal can be converted to decimal ("numified") form using this
convention: minor and lesser parts are given (at least) three decimal digits
each. For example, 1.2.3 becomes 1.002003. 1.20.3 becomes 1.020003. This can
give some surprise which has bitten Perl programmers, novice and expert alike.
In fact, it is the major gotcha when dealing with version numbers in Perl. For
example '0.02' (a decimal form) numifies to 0.02, but 'v0.02' (a dotted decimal
form) numifies to 0.002. Hence, v0.02 is less than 0.02 or even 0.01 when
compared using version->parse(). Another gotcha is when a module author decides
to go from 0.02 to 0.2.1 or 0.02.1. 0.02 (a decimal form) numifies to 0.02 while
0.2.1 or 0.02.1 (dotted decimal) numifies to 0.002001. Hence, going from 0.02 to
0.02.1 will actually I<decrease> your version number. I recommend using x.yyy if
you use decimal form, i.e. start from 0.001 and not 0.01. It will support you
going smoothly to dotted decimal if you decide to do it one day.

The numification is also problematic when a number part is > 999, e.g. 1.2.1234.
This breaks version comparison when comparison is done with version->parse().

Aside from the abovementioned two styles, there is another: CPAN
distributions/modules can add an underscore in the last part of the version
number to signify alpha/dev/trial release, e.g. 1.2.3_01. PAUSE will not index
such releases, so testers will need to specify an explicit version number to
install, e.g. C<cpanm Foo@1.2.3_01>. In some cases you need to pay attention when
comparing this kind of version numbers.

=head2 Checking if a string is a valid version number

To check if a string is a valid Perl version number, you can do:

 version->parse($str)

which will die if C<$str> contains an invalid version string. version.pm can
handle the "v" prefix, (e.g. "v1.2"), dotted-decimal (e.g. "1.2.3" but also
"1.2.3.4.5"), as well as alpha/dev/trial part (e.g. "v1.1.1_001").

=head2 Parsing a version number

version->parse, obviously enough, is used to parse a version number string into
a structure:

 use Data::Dump;
 dd( version->parse("1.2.3") );

which prints:

 bless({ original => "1.2.3", qv => 1, version => [1, 2, 3] }, "version")

However:

 dd( version->parse("1.2.3_01") );

prints:

 bless({ alpha => 1, original => "1.2.3_01", qv => 1, version => [1, 2, 301] }, "version")

=head2 Comparing version numbers

You can compare two version numbers again using version->parse():

 version->parse($str1) <=> version->parse($str2)

For example:

 version->parse("1.2.3") <=> version->parse("v1.3.0");  # => -1

Be careful when dealing with alpha/dev/trial version:

 version->parse("1.2.3_01") <=> version->parse("v1.2.4")  ;  # => 1
 version->parse("1.2.3_01") <=> version->parse("v1.2.301");  # => 0
 version->parse("1.2.3_01") <=> version->parse("v1.2.400");  # => -1

=head2 Normalizing a version number

To normalize a version number:

 version->parse($str)->normal

This will add a "v" prefix, force a dotted decimal form, and remove insignifcant
zeros. Examples:

 version->parse(1.2)      ->normal; # => "v1.200.0"
 version->parse("1.2.3")  ->normal; # => "v1.2.3"
 version->parse("1.2.30") ->normal; # => "v1.2.30"
 version->parse("1.2.030")->normal; # => "v1.2.30"

=head2 Incrementing a version number

Some modules like L<Perl::Version> and L<Versioning::Scheme::Perl> can help
increase version numbers (or whichever part of the number). The last one can
also decrement parts.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<version>

Author: L<LEONT|https://metacpan.org/author/LEONT>

=item L<Perl::Version>

Author: L<BDFOY|https://metacpan.org/author/BDFOY>

=item L<Versioning::Scheme::Perl>

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

 % cpanm-cpanmodules -n VersionNumber::Perl

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries VersionNumber::Perl | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=VersionNumber::Perl -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::VersionNumber::Perl -E'say $_->{module} for @{ $Acme::CPANModules::VersionNumber::Perl::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-VersionNumber-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-VersionNumber-Perl>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-VersionNumber-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
