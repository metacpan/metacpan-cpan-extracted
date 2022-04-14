package App::SerializeUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-20'; # DATE
our $DIST = 'App-SerializeUtils'; # DIST
our $VERSION = '0.165'; # VERSION

1;
# ABSTRACT: Utilities for serialization tasks

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SerializeUtils - Utilities for serialization tasks

=head1 VERSION

This document describes version 0.165 of App::SerializeUtils (from Perl distribution App-SerializeUtils), released on 2022-03-20.

=head1 SYNOPSIS

 $ script-that-produces-json | json2yaml

=head1 DESCRIPTION

This distributions provides the following command-line utilities related to
serialization:

=over

=item * L<check-json>

=item * L<check-phpser>

=item * L<check-yaml>

=item * L<json2json>

=item * L<json2perl>

=item * L<json2perlcolor>

=item * L<json2phpser>

=item * L<json2sereal>

=item * L<json2sexp>

=item * L<json2storable>

=item * L<json2yaml>

=item * L<perl2json>

=item * L<perl2perl>

=item * L<perl2perlcolor>

=item * L<perl2phpser>

=item * L<perl2sereal>

=item * L<perl2sexp>

=item * L<perl2storable>

=item * L<perl2yaml>

=item * L<phpser2json>

=item * L<phpser2perl>

=item * L<phpser2perlcolor>

=item * L<phpser2sereal>

=item * L<phpser2sexp>

=item * L<phpser2storable>

=item * L<phpser2yaml>

=item * L<pp-json>

=item * L<pp-perl>

=item * L<pp-yaml>

=item * L<sereal2json>

=item * L<sereal2perl>

=item * L<sereal2perlcolor>

=item * L<sereal2phpser>

=item * L<sereal2sexp>

=item * L<sereal2storable>

=item * L<sereal2yaml>

=item * L<serializeutils-convert>

=item * L<sexp2json>

=item * L<sexp2perl>

=item * L<sexp2perlcolor>

=item * L<sexp2phpser>

=item * L<sexp2sereal>

=item * L<sexp2storable>

=item * L<sexp2yaml>

=item * L<storable2json>

=item * L<storable2perl>

=item * L<storable2perlcolor>

=item * L<storable2phpser>

=item * L<storable2sereal>

=item * L<storable2sexp>

=item * L<storable2yaml>

=item * L<yaml2json>

=item * L<yaml2perl>

=item * L<yaml2perlcolor>

=item * L<yaml2phpser>

=item * L<yaml2sereal>

=item * L<yaml2sexp>

=item * L<yaml2storabls>

=item * L<yaml2yaml>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-SerializeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SerializeUtils>.

=head1 SEE ALSO

L<Data::Dump>

L<JSON>

L<PHP::Serialization>

L<Sereal>

L<Storable>

L<YAML>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2018, 2017, 2015, 2014, 2013, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SerializeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
