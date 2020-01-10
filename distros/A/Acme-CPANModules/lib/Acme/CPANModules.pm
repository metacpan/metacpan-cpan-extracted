package Acme::CPANModules;

our $DATE = '2019-12-24'; # DATE
our $VERSION = '0.1.5'; # VERSION

1;
# ABSTRACT: CPAN modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules - CPAN modules

=head1 SPECIFICATION VERSION

0.1

=head1 VERSION

This document describes version 0.1.5 of Acme::CPANModules (from Perl distribution Acme-CPANModules), released on 2019-12-24.

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

For categorizing CPAN authors, there are also the L<Acme::CPANAuthors> project,
complete with L<its own website|http://acme.cpanauthors.org/>.

Acme::CPANModules is another mechanism to help, to let someone categorize
modules in whatever way she likes.

A related website/online service for "CPAN modules" is coming (when I eventually
get to it :-), or perhaps when I get some help).

=head1 CREATING AN ACME::CPANMODULES MODULE

The first step is to decide on a name of the module. It must be under the
C<Acme::CPANModules::> namespace. I recommend that you prefix your module with
your CPAN ID, e.g. L<Acme::CPANModules::PERLANCAR::Unbless> or
L<Acme::CPANModules::PERLANCAR::Task::PickingRandomLinesFromFile>.

Inside the module, you must declare a hash named C<$LIST>:

 our $LIST = {
     ...
 };

The names of the keys in the hash must follow L<DefHash> convention. The basic
structure is this:

 # an example module list
 {
     summary => 'My favorite modules',
     description => <<'_',
 (Some longer description, in Markdown format)

 This is just a list of my favorite modules.
 _

     ## define features to be used by entries. this can be used to generate a
     ## feature comparison matrix among the entries.
     # entry_features => { # optional
     #     feature1 => 'Summary of feature1',
     #     feature2 => 'Summary of feature2',
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
     #     feature1 => 1,
     #     feature2 => 0,
     #     feature4 => {value=>0, summary=>'Irrelevant because foo bar'},
     #     ...
     # },

     ## specify Bencher scenario participant's properties; "bench_" prefix will
     ## be removed when creating participant record.
     # bench_code => sub { ... }, # or
     # bench_code_template => 'Data::Dump::dump(<data>)',
     # ...

 }

That's it. After you have completed your list, publish your Acme::CPANModules
module to CPAN.

If you are using L<Dist::Zilla> to release your distribution, this
L<Pod::Weaver> plugin might be useful for you:
L<Pod::Weaver::Plugin::Acme::CPANModules>. It will create an C<=head2 Included
modules> section which is POD rendering of your module list so users reading
your module's documentation can immediately read your list.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

C<Acme::CPANModules::*> modules

L<cpanmodules> from L<App::cpanmodules>

L<Bencher>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
