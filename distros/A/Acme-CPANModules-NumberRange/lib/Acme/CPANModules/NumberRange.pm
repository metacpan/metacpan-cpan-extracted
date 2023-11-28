package Acme::CPANModules::NumberRange;

use strict;

use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-NumberRange'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "List of modules that handle number ranges",
    description => <<'_',

**Checking membership, formatting**

<pm:Array::IntSpan>

<pm:Array::RealSpan>

<pm:Number::Range>

<pm:Number::RangeTracker>

<pm:Range::Object::Serial>

<pm:Set::IntSpan>

<pm:Set::IntSpan::Fast>

<pm:Set::IntSpan::Fast::XS>

<pm:Set::IntSpan::Island>

<pm:Tie::Array::IntSpan>


**Partitioning**

<pm:Aray::IntSpan::Partition>


**Formatting**

<pm:Number::Continuation>

<pm:Set::IntSpan::Util>

_
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules that handle number ranges

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::NumberRange - List of modules that handle number ranges

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::NumberRange (from Perl distribution Acme-CPANModules-NumberRange), released on 2023-10-29.

=head1 DESCRIPTION

B<Checking membership, formatting>

L<Array::IntSpan>

L<Array::RealSpan>

L<Number::Range>

L<Number::RangeTracker>

L<Range::Object::Serial>

L<Set::IntSpan>

L<Set::IntSpan::Fast>

L<Set::IntSpan::Fast::XS>

L<Set::IntSpan::Island>

L<Tie::Array::IntSpan>

B<Partitioning>

L<Aray::IntSpan::Partition>

B<Formatting>

L<Number::Continuation>

L<Set::IntSpan::Util>

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Array::IntSpan>

Author: L<DDUMONT|https://metacpan.org/author/DDUMONT>

=item L<Array::RealSpan>

Author: L<GENE|https://metacpan.org/author/GENE>

=item L<Number::Range>

Author: L<LARRYSH|https://metacpan.org/author/LARRYSH>

=item L<Number::RangeTracker>

Author: L<COVINGTON|https://metacpan.org/author/COVINGTON>

=item L<Range::Object::Serial>

Author: L<TOKAREV|https://metacpan.org/author/TOKAREV>

=item L<Set::IntSpan>

Author: L<SWMCD|https://metacpan.org/author/SWMCD>

=item L<Set::IntSpan::Fast>

Author: L<ANDYA|https://metacpan.org/author/ANDYA>

=item L<Set::IntSpan::Fast::XS>

Author: L<ANDYA|https://metacpan.org/author/ANDYA>

=item L<Set::IntSpan::Island>

Author: L<MARTINK|https://metacpan.org/author/MARTINK>

=item L<Tie::Array::IntSpan>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Aray::IntSpan::Partition>

=item L<Number::Continuation>

Author: L<SCHUBIGER|https://metacpan.org/author/SCHUBIGER>

=item L<Set::IntSpan::Util>

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

 % cpanm-cpanmodules -n NumberRange

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries NumberRange | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=NumberRange -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::NumberRange -E'say $_->{module} for @{ $Acme::CPANModules::NumberRange::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-NumberRange>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-NumberRange>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-NumberRange>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
