package Acme::CPANModules::FormattingDate;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-FormattingDate'; # DIST
our $VERSION = '0.002'; # VERSION

my $text = <<'_';
**Overview**

Date formatting modules can be categorized by their expected input format and
the formatting styles.

Input format: Some modules accept date in the form of Unix epoch (an integer),
or a list of integer produced by running the epoch through the builtin gmtime()
or localtime() function. Some others might expect the date as <pm:DateTime>
object. For formatting style: there's strftime in the <pm:POSIX> core module,
and then there's the others.

This list is organized using the latter criteria (formatting style).

**strftime (and variants)**

The <pm:POSIX> module provides the `strftime()` routine which lets you format
using a template string containing sprintf-style conversions like `%Y` (for
4-digit year), `%m` (2-digit month number from 1-12), and so on. There's also
<pm:Date::strftimeq> which provides an extension to this.

You can actually add some modifiers for the conversions to set
width/zero-padding/alignment, like you can do with sprintf (e.g. `%03d`
supposing you want 3-digit day of month numbers). But this feature is
platform-dependent.

**yyyy-mm-dd template**

This "yyyy-mm-dd" (for lack of a better term) format is much more commonly used
in the general computing world, from spreadsheets to desktop environment clocks.
And this format is probably older than strftime. The template is more intuitive
to use for people as it gives a clear picture of how wide each component (and
the whole string) will be.

There are some modules you can use to format dates using this style. First of
all there's <pm:Date::Formatter>. I find its API a little bit annoying, from the
verbose date component key names and inconsistent usage of plurals, to having to
use a separate method to "create the formatter" first.

**PHP**

PHP decided to invent its own date template format. Its `date()` function
accepts template string in which you specify single letter conversions like `Y'
(for 4-digit year), `y` (2-digit year), and so on. Some of the letters mean the
same like their counterpart in strftime, but some are different (examples: `i`,
`a`, `M`, and so on). The use of single letter means it's more concise, but the
format becomes unsuitable if you want to put other stuffs (like some string
alphabetical literals) in addition to date components.

In Perl, you can use the <pm:PHP::DateTime> to format dates using PHP `date()`
format.

_

our $LIST = {
    summary => 'List of various methods to format dates',
    description => $text,
    tags => ['task'],
    entries => [
        map { +{module=>$_} }
            do { my %seen; grep { !$seen{$_}++ }
                 ($text =~ /<pm:(\w+(?:::\w+)+)>/g)
             }
    ],
};

1;
# ABSTRACT: List of various methods to format dates

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::FormattingDate - List of various methods to format dates

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::FormattingDate (from Perl distribution Acme-CPANModules-FormattingDate), released on 2023-10-29.

=head1 DESCRIPTION

B<Overview>

Date formatting modules can be categorized by their expected input format and
the formatting styles.

Input format: Some modules accept date in the form of Unix epoch (an integer),
or a list of integer produced by running the epoch through the builtin gmtime()
or localtime() function. Some others might expect the date as L<DateTime>
object. For formatting style: there's strftime in the L<POSIX> core module,
and then there's the others.

This list is organized using the latter criteria (formatting style).

B<strftime (and variants)>

The L<POSIX> module provides the C<strftime()> routine which lets you format
using a template string containing sprintf-style conversions like C<%Y> (for
4-digit year), C<%m> (2-digit month number from 1-12), and so on. There's also
L<Date::strftimeq> which provides an extension to this.

You can actually add some modifiers for the conversions to set
width/zero-padding/alignment, like you can do with sprintf (e.g. C<%03d>
supposing you want 3-digit day of month numbers). But this feature is
platform-dependent.

B<yyyy-mm-dd template>

This "yyyy-mm-dd" (for lack of a better term) format is much more commonly used
in the general computing world, from spreadsheets to desktop environment clocks.
And this format is probably older than strftime. The template is more intuitive
to use for people as it gives a clear picture of how wide each component (and
the whole string) will be.

There are some modules you can use to format dates using this style. First of
all there's L<Date::Formatter>. I find its API a little bit annoying, from the
verbose date component key names and inconsistent usage of plurals, to having to
use a separate method to "create the formatter" first.

B<PHP>

PHP decided to invent its own date template format. Its C<date()> function
accepts template string in which you specify single letter conversions like C<Y'
(for 4-digit year),>yC<(2-digit year), and so on. Some of the letters mean the
same like their counterpart in strftime, but some are different (examples:>iC<,
>aC<,>M`, and so on). The use of single letter means it's more concise, but the
format becomes unsuitable if you want to put other stuffs (like some string
alphabetical literals) in addition to date components.

In Perl, you can use the L<PHP::DateTime> to format dates using PHP C<date()>
format.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Date::strftimeq>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Date::Formatter>

Author: L<BIANCHINI|https://metacpan.org/author/BIANCHINI>

=item L<PHP::DateTime>

Author: L<BLUEFEET|https://metacpan.org/author/BLUEFEET>

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

 % cpanm-cpanmodules -n FormattingDate

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries FormattingDate | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=FormattingDate -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::FormattingDate -E'say $_->{module} for @{ $Acme::CPANModules::FormattingDate::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-FormattingDate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-FormattingDate>.

=head1 SEE ALSO

L<Bencher::Scenario::FormattingDate>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-FormattingDate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
