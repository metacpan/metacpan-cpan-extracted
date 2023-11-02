# no code
## no critic: TestingAndDebugging::RequireUseStrict
package Acme::CPANModules;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-01'; # DATE
our $DIST = 'Acme-CPANModules'; # DIST
our $VERSION = '0.1.12'; # VERSION

1;
# ABSTRACT: List of CPAN modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules - List of CPAN modules

=head1 SPECIFICATION VERSION

0.1

=head1 VERSION

This document describes version 0.1.12 of Acme::CPANModules (from Perl distribution Acme-CPANModules), released on 2023-11-01.

=head1 DESCRIPTION

With the multitude of modules that are available on CPAN, it is sometimes
difficult for a user to choose an appropriate module for a task or find other
modules related in some ways to a module. Various projects like L<CPAN
Ratings|http://cpanratings.perl.org/> (where users rate and review a
distribution; now no longer accepting new submission) or
L<MetaCPAN|https://metacpan.org/> (which has a C<++> feature where logged-in
users can press a button to C<++> a module and the website will tally the number
of C<++>'s a distribution has) help to some extent. There are also various blog
posts by Perl programmers which review modules, e.g. L<CPAN Module Reviews by
Neil Bowers|http://neilb.org/reviews/>.

Acme::CPANModules is another mechanism to help, to let someone categorize
modules in whatever way she likes.

A related website/online service for "CPAN modules" is coming (when I eventually
get to it :-), or perhaps when I get some help).

=head1 CREATING AN ACME::CPANMODULES MODULE

The first step is to decide on the name of your module. It must be under the
C<Acme::CPANModules::> namespace. For example, if you create a list of your
favorite modules, you can use C<Acme::CPANModules::YOURCPANID::Favorite>. Or if
you are creating a list of modules that predict the future, you can choose
C<Acme::CPANModules::PredictingTheFuture>. See recommendations for module name
in L</module name> under L</RECOMMENDATIONS>.

Inside the module, you must declare a hash named C<$LIST>:

 our $LIST = {
     ...
 };

The names of the keys in the hash must follow L<DefHash> convention. The basic
structure is this:

 # an example module list
 {
     summary => 'List of my favorite modules',  # for recommendation of summary, see Recommendations section
     description => <<'_',
 (Some longer description, in Markdown format)

 This is just a list of my favorite modules.
 _

     ## define features to be used by entries. this can be used to generate a
     ## feature comparison matrix among the entries.
     # entry_features => { # optional
     #     feature1 => {summary=>'Summary of feature1', schema=>'str*'}, # default schema is 'bool' if not specified
     #     feature2 => {summary=>'Summary of feature2', ...},
     #     feature3 => {...},
     #     feature4 => {...},
     #     ...
     # },

     entries => [
         {...},
         ...
     ],

     ## specify Bencher scenario properties; "bench_" prefix will be removed
     ## when creating scenario record. see Bencher for more details.
     # bench_datasets => [ ... ],
     # bench_extra_modules => [ ... ],

     ## optional. Instruct cpanmodules script to not show the entries when
     ## viewing the list. This is sometimes convenient when the description
     ## already mentions all the entries.
     #'x.app.cpanmodules.show_entries' => 0,

 }

Each entry is another DefHash:

 # an example module entry
 {
     module => 'Data::Dump',
     summary => 'Pretty output',
     description => <<'_',
 Data::Dump is my favorite dumping module because it outputs Perl code that
 is pretty and readable.
 _

     # rating => 10, # optional, on a 1-10 scale

     # alternate_modules => [...], # if you are reviewing an undesirable module and want to suggest better alternative(s)

     # related_modules => ['Data::Dump::Color', 'Data::Dumper'], # if you want to specify related modules that are not listed on the other entries of the same list

     ## specify which features this entry supports/doesn't support. this can be
     ## used to generate feature comparison matrix. see
     ## Acme::CPANModulesUtil::FeatureMatrix.
     # features => {
     #     feature1 => 'foo',   # string, value is "foo"
     #     feature2 => 0,       # bool, value is false ("no")
     #                          # since feature3 is not specified for this module, the value is "N/A"
     #     feature4 => {value=>0, summary=>'Irrelevant because foo bar'},  # bool, value is false. with additional note.
     #     ...
     # },

     ## specify Bencher scenario participant's properties; "bench_" prefix will
     ## be removed when creating participant record.
     # bench_code => sub { ... }, # or
     # bench_code_template => 'Data::Dump::dump(<data>)',
     # ...

     # list what functions are in the module. currently this is mainly used for
     # specifying benchmark instructions for the functions.
     functions => {
         func1 => {
             bench_code_template => 'Data::Dump::dump([])',
         },
     },

 }

That's it. After you have completed your list, publish your Acme::CPANModules
module to CPAN.

Here's a sample of one of the simplest C<$LIST> you can have:

 $LIST = {
     summary => 'Modules that predict the future',
     entries => [
         {module=>'Zorb'},
         {module=>'Madame::Zita'},
     ],
 };

Here's another, more expanded sample:

 $LIST = {
     summary => 'Modules that predict the future',
     description => <<'_',

This list catalogs modules that predict the future. Yes, the future is
unpredictable. But we can try anyway, right?

_
     entries => [
         {
             module => 'Zorb',
             summary => 'Contact the API for the strange crystal Zorb',
             description => <<'_',

This module is an API client to Zorb, a strange crystal that supposedly fell
from the sky in 2017 near Ozark, that can change color depending on what you
feed to it. The API connects to Zorb API server managed by Crooks, Inc.

_
         },
         {
             module => 'Madame::Zita',
             summary => 'Ask Madame Zita the fortune teller',
         },
     ],
 };

For more examples, see existing C<Acme::CPANModules::*> modules on CPAN.

If you are using L<Dist::Zilla> to release your distribution, this
L<Pod::Weaver> plugin might be useful for you:
L<Pod::Weaver::Plugin::Acme::CPANModules>. It will create an C<=head2 Included
modules> section which is POD rendering of your module list so users reading
your module's documentation can immediately read your list.

=head1 RECOMMENDATIONS

=head2 module name

An Acme::CPANModules module is named under C<Acme::CPANModules::> namespace.

A personal list should go under your CPAN ID's subnamespace, e.g.
C<Acme::CPANModules::YOURCPANID::Favorite> or
C<Acme::CPANModules::YOURCPANID::Avoided>.

Avoid having C<Modules> in the name as it is superfluous, e.g.
C<Acme::CPANModules::TextTable> instead of
C<Acme::CPANModules::TextTableModules>.

Verb is preferrably written in present participle form, e.g. for a list of
modules that parse JSON: C<Acme::CPANModules::ParsingJSON> instead of
C<Acme::CPANModules::ParseJSON>.

Noun that refers to the modules (entries) is preferrably written in plural
forms, e.g. C<Acme::CPANModules::JSONParsers> instead of
C<Acme::CPANModules::JSONParser>.

=head2 list summary

The list summary normally becomes the Acme::CPANModules module's Abstract.

It is recommended to start the summary with "List of modules which/that" or
"List of my ... modules" to make it clearer that the Acme::CPANModules module
only contains a list of other modules, instead of an actual implementation.

Some preferred examples:

Some non-preferred examples:

=head2 entry rating

Should only be used for personal lists.

=head2 module bundle name

A distribution that contains several C<Acme::CPANModules::*> modules should be
named C<Acme-CPANModulesBundle-*>.

In general, an C<Acme::CPANModulesBundle::> module should be named like an
C<Acme::CPANModules::*> module. See recommendations in L</"module name">.

=head2 module bundle abstract

An C<Acme::CPANModulesBundle::> module should have abstract that begins with
"Bundle of ...".

=head2 other modules

Other suggested namespaces:

=over

=item * C<Acme::CPANModulesUtil::>,

Utility modules that do not contain lists of modules themselves.

=item * C<Acme::CPANModulesUtilBundle::>,

For distribution that contains several C<Acme::CPANModulesUtil::*> modules.

=item * C<Acme::CPANModulesRole::>

For role related to C<Acme::CPANModules>.

=item * C<Acme::CPANModulesRoleBundle::>

For distribution that contains several C<Acme::CPANModulesRole::> modules.

=back

=head1 USING ACME::CPANMODULES MODULES

You can install the L<cpanmodules> CLI script (from the L<App::cpanmodules>
distribution). It can list installed Acme::CPANModules modules and view list
entries. To install all modules listed on an Acme::CPANModules module, you can
do something like:

 % cpanmodules ls-entries Org | cpanm -n

Putting similar/related modules together in an Acme::CPANModules can also help
the L<lcpan> script find related modules (C<lcpan related-mods>). See the lcpan
documentation or C<lcpan related-mods --help> for more details.

As mentioned earlier, a website/online service that collects and indexes all
Acme::CPANModules modules on CPAN is coming in the future. Meanwhile, there's
MetaCPAN.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules>.

=head1 SEE ALSO

C<Acme::CPANModules::*> modules

L<cpanmodules> from L<App::cpanmodules>

L<Bencher>

For categorizing CPAN authors, there are also the L<Acme::CPANAuthors> project,
complete with L<its own website|http://acme.cpanauthors.org/>.

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

This software is copyright (c) 2023, 2022, 2021, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
