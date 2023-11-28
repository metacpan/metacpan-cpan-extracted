# no code
## no critic: TestingAndDebugging::RequireUseStrict
package Acme::Thing;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-19'; # DATE
our $DIST = 'Acme-Thing'; # DIST
our $VERSION = '0.1.0'; # VERSION

1;
# ABSTRACT: Represent anything as Perl (CPAN) module

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Thing - Represent anything as Perl (CPAN) module

=head1 SPECIFICATION VERSION

0.1

=head1 VERSION

This document describes version 0.1.0 of Acme::Thing (from Perl distribution Acme-Thing), released on 2023-03-19.

=head1 DESCRIPTION

C<Acme::Thing> is a convention for representing anything as a Perl
module/distribution. Custom prerequisite phase/relationship in distribution
metadata can be used to relate the thing to other things. The C<get_thing_attrs>
class method can be used to rerieve attributes of the thing. The module's POD
can be used to document the thing.

=head2 Naming convention

The module should be named C<Acme::Thing::$SUBNAMESPACE::$NAME> where
C<$SUBNAMESPACE> is one or more levels of subnamespaces and C<$NAME> is the
name/title of the thing. Both C<$SUBNAMESPACE> and C<$TITLE> should use
C<CamelCase> notation and should be in singular noun form whenever possible.
Underscore is used to separate name parts. For example, for a TV series the
C<$NAME> could be the title of the series using the IMDB convention:

 Acme::Thing::TVSeries::BreakingBad_2008_2013
 Acme::Thing::TvSeries::CornerGas_2004_2009

and for a book title the C<$NAME> could be the title (without the subtitle) of
the book, preferrably with the publication year. Subsequent editions of a book
should be named using the C<nE> notation. Examples:

 Acme::Thing::Book::ProgrammingPerl_1991
 Acme::Thing::Book::ProgrammingPerl_4E_2012

=head2 Relationship with other things

TBD.

=head2 Attributes

The module must provide a class method called C<get_thing_attrs> (by itself or
by inheritance, doesn't matter), which must return a L<DefHash> containng
attributes of the thing. The required attributes are:

=over

=item * title

Title of the thing, in a format common for that thing.

=back

For example, for a book title:

 {
   title => "Programming Perl",
   isbn => ...,
   year => 1991,
   summary => ...,
   description => ...,
   ...
 }

For a TV series:

 {
   title => "Breaking Bad",
   year_first => 2008,
   year_last => 2013,
   imdb_title_id => ...,
   summary => ...,
   description => ...,
   ...
 }

=head2 Why?

Now comes the harder question: why use Perl module/distribution to represent
seomthing at all, other than an actual Perl module? Releasing as Perl
distribution and module leverages a few things: 1) the CPAN distribution
metadata (see L<CPAN::Meta>) where a distribution can depend (relate) to other
modules (other things); 2) the CPAN infrastructure where revisions of the thing
can be released, distributed, tested, and installed to target systems; 3) the OO
feature of the Perl language where a user can interact with a thing (e.g.
download a TV series poster or trailer, etc).

Of course, none of the above suggest that a generic representation like
C<Acme::Thing> is better than a more specific one, e.g. C<WebService::ISBNDB>
for books.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-Thing>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-Thing>.

=head1 SEE ALSO

L<DefHash>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-Thing>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
