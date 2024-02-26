package Acme::CPANModules::Parse::HumanDate;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-31'; # DATE
our $DIST = 'Acme-CPANModules-Parse-HumanDate'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "List of modules that parse human date/time expression",
    entries => [
        {
            module=>'DateTime::Format::Natural',
            description => <<'_',

Compared to <pm:DateTime::Format::Flexible>, this module can also parse
duration in addition to date/time, e.g.:

    2 years 3 months

And it also can extract the date expression from a longer string.

Speed-wise, I'd say the two modules are roughly comparable. For some patterns
one might be faster than the other.

_
            bench_code_template => 'DateTime::Format::Natural->new->parse_datetime(<str>)',
        },
        {
            module=>'DateTime::Format::Flexible',
            description => <<'_',

One advantage of this over <pm:DateTime::Format::Natural> is its time zone
support, e.g.:

    yesterday 8pm UTC
    yesterday 20:00 +0800
    yesterday 20:00 Asia/Jakarta

Speed-wise, I'd say the two modules are roughly comparable. For some patterns
one might be faster than the other.

_
            bench_code_template => 'DateTime::Format::Flexible->new->parse_datetime(<str>)',
        },

        {
            module => 'Date::Parse',
            description => <<'_',

This module can parse several formats, but does not really fall into "human
date/time parser" as it lacks support for casual expression like "yesterday" or
3 hours ago".

_
        },
    ],

    bench_datasets => [
        {args=>{str => 'yesterday'}},
        {args=>{str => '2 days ago'}},
        {args=>{str => '2021-09-06 20:03:00'}},
    ],
};

1;
# ABSTRACT: List of modules that parse human date/time expression

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Parse::HumanDate - List of modules that parse human date/time expression

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::Parse::HumanDate (from Perl distribution Acme-CPANModules-Parse-HumanDate), released on 2023-10-31.

=head1 DESCRIPTION

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<DateTime::Format::Natural>

Author: L<SCHUBIGER|https://metacpan.org/author/SCHUBIGER>

Compared to L<DateTime::Format::Flexible>, this module can also parse
duration in addition to date/time, e.g.:

 2 years 3 months

And it also can extract the date expression from a longer string.

Speed-wise, I'd say the two modules are roughly comparable. For some patterns
one might be faster than the other.


=item L<DateTime::Format::Flexible>

Author: L<THINC|https://metacpan.org/author/THINC>

One advantage of this over L<DateTime::Format::Natural> is its time zone
support, e.g.:

 yesterday 8pm UTC
 yesterday 20:00 +0800
 yesterday 20:00 Asia/Jakarta

Speed-wise, I'd say the two modules are roughly comparable. For some patterns
one might be faster than the other.


=item L<Date::Parse>

Author: L<ATOOMIC|https://metacpan.org/author/ATOOMIC>

This module can parse several formats, but does not really fall into "human
date/time parser" as it lacks support for casual expression like "yesterday" or
3 hours ago".


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

 % cpanm-cpanmodules -n Parse::HumanDate

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Parse::HumanDate | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Parse::HumanDate -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Parse::HumanDate -E'say $_->{module} for @{ $Acme::CPANModules::Parse::HumanDate::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module contains benchmark instructions. You can run a
benchmark for some/all the modules listed in this Acme::CPANModules module using
the L<bencher> CLI (from L<Bencher> distribution):

    % bencher --cpanmodules-module Parse::HumanDate

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Parse-HumanDate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Parse-HumanDate>.

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

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Parse-HumanDate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
