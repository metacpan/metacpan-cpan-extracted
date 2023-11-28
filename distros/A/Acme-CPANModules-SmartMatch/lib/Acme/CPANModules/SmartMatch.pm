package Acme::CPANModules::SmartMatch;

use strict;
use warnings;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-09'; # DATE
our $DIST = 'Acme-CPANModules-SmartMatch'; # DIST
our $VERSION = '0.002'; # VERSION

my $text = <<'_';
**About smart match**

Smart matching, via the operator `~~`, was introduced in perl 5.10 (released
2007). It's probably inspired by Perl 6 (now called Raku)'s `given/when` and/or
Ruby's `case` and `===` operator that can "do the right/smart thing" in a `case`
statement. Smart matching was indeed introduced along the new `switch` in perl
5.10.

What can smart match do? A whole lot. It can do string equality like `eq` if
given a string on the left hand side and a string on the right hand side. Or it
can do numeri equality like `==` when both sides are numbers. It can do regex
matching like `=~` if the left hand side is a scalar and the right hand side is
a regexp.

But wait, there's (much) more. Interesting things begin when the left/right hand
side is an array/hash/code/object. `$str ~~ @ary`, probably the most common
use-case for smart matching, can do value-in-array checking, equivalent to `grep
{ $str eq $_ } @ary` but with short-circuiting capability. Then there's `$re ~~
@ary` which can perform regex matching over the elements of array. Now what
about when the right hand side is an arrayref or hashref? Or the left hand side?
What if the array is an array of regexes? Or a mix of other types?

You need a full-page table as a reference of what will happen in smart matching,
depending on the combination of operands. Things got complex real fast.
Behaviors were changed from release to release, starting from 5.10.1. Then
nobody was sure what smart matching should or should not do exactly.

In the end almost everyone agrees that smart matching is a bad fit for a weakly
typed language like Perl. The programmer needs to be explicit on what type of
operation should be done by specifying the appropriate /operator/ (e.g. `==` vs
`eq`) instead of the operator deducing what operation needs to be done depending
on the operand, because in Perl the operand's type is unclear. Mainly, a scalar
can be a string, or a number, or a bool, or all.


**The roadmap to removal**

In perl 5.18 (2013), 6 years after being introduced and used by programmers
without warning, smart match was declared as experimental, which is weird if you
think about it. You now have to add `use experimental "smartmatch"' to silence
the warning. What happens to the `switch` statement then? Since it's tied to
smart matching, it also gets the same fate: became experimental in 5.18.

In perl 5.38 (2023) smart match is deprecated. You can no longer silence the
warning with "use experimental 'smartmatch'" and must replace the use of smart
match with something else.

Perl 5.40 (planned 2024) will remove smart match, resulting in a syntax error if
you still use it.


**Modules**

However, if you still miss smart matching, some modules have been written to
give you somewhat similar feature.

<pm:match::smart> (as `|M|` operator or as function `match`) gives you a
similar behaviour to perl's own `~~`.

<pm:match::simple>, also by the author of `match::smart`, offers a simplified
version of smart matching. Still it has 8 kinds of behavior depending on the
/right/ hand side.

Also see <pm:match::simple::sugar> which gives you `when`, `then`, and `numeric`
for use in a `for()` statement as a switch/use alternative.

<pm:Smart::Match> offers a bunch of functions related to matching. Probably too
low-level to use if you just want a smart match replacement.

_

our $LIST = {
    summary => 'List of modules to do smart matching',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules to do smart matching

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::SmartMatch - List of modules to do smart matching

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::SmartMatch (from Perl distribution Acme-CPANModules-SmartMatch), released on 2023-07-09.

=head1 DESCRIPTION

B<About smart match>

Smart matching, via the operator C<~~>, was introduced in perl 5.10 (released
2007). It's probably inspired by Perl 6 (now called Raku)'s C<given/when> and/or
Ruby's C<case> and C<===> operator that can "do the right/smart thing" in a C<case>
statement. Smart matching was indeed introduced along the new C<switch> in perl
5.10.

What can smart match do? A whole lot. It can do string equality like C<eq> if
given a string on the left hand side and a string on the right hand side. Or it
can do numeri equality like C<==> when both sides are numbers. It can do regex
matching like C<=~> if the left hand side is a scalar and the right hand side is
a regexp.

But wait, there's (much) more. Interesting things begin when the left/right hand
side is an array/hash/code/object. C<$str ~~ @ary>, probably the most common
use-case for smart matching, can do value-in-array checking, equivalent to C<grep
{ $str eq $_ } @ary> but with short-circuiting capability. Then there's C<$re ~~
@ary> which can perform regex matching over the elements of array. Now what
about when the right hand side is an arrayref or hashref? Or the left hand side?
What if the array is an array of regexes? Or a mix of other types?

You need a full-page table as a reference of what will happen in smart matching,
depending on the combination of operands. Things got complex real fast.
Behaviors were changed from release to release, starting from 5.10.1. Then
nobody was sure what smart matching should or should not do exactly.

In the end almost everyone agrees that smart matching is a bad fit for a weakly
typed language like Perl. The programmer needs to be explicit on what type of
operation should be done by specifying the appropriate /operator/ (e.g. C<==> vs
C<eq>) instead of the operator deducing what operation needs to be done depending
on the operand, because in Perl the operand's type is unclear. Mainly, a scalar
can be a string, or a number, or a bool, or all.

B<The roadmap to removal>

In perl 5.18 (2013), 6 years after being introduced and used by programmers
without warning, smart match was declared as experimental, which is weird if you
think about it. You now have to add C<use experimental "smartmatch"' to silence
the warning. What happens to the>switch` statement then? Since it's tied to
smart matching, it also gets the same fate: became experimental in 5.18.

In perl 5.38 (2023) smart match is deprecated. You can no longer silence the
warning with "use experimental 'smartmatch'" and must replace the use of smart
match with something else.

Perl 5.40 (planned 2024) will remove smart match, resulting in a syntax error if
you still use it.

B<Modules>

However, if you still miss smart matching, some modules have been written to
give you somewhat similar feature.

L<match::smart> (as C<|M|> operator or as function C<match>) gives you a
similar behaviour to perl's own C<~~>.

L<match::simple>, also by the author of C<match::smart>, offers a simplified
version of smart matching. Still it has 8 kinds of behavior depending on the
/right/ hand side.

Also see L<match::simple::sugar> which gives you C<when>, C<then>, and C<numeric>
for use in a C<for()> statement as a switch/use alternative.

L<Smart::Match> offers a bunch of functions related to matching. Probably too
low-level to use if you just want a smart match replacement.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<match::smart>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

=item L<match::simple>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

=item L<match::simple::sugar>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

=item L<Smart::Match>

Author: L<LEONT|https://metacpan.org/author/LEONT>

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

 % cpanm-cpanmodules -n SmartMatch

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries SmartMatch | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=SmartMatch -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::SmartMatch -E'say $_->{module} for @{ $Acme::CPANModules::SmartMatch::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-SmartMatch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-SmartMatch>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-SmartMatch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
