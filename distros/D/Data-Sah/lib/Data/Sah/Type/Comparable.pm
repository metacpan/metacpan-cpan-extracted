package Data::Sah::Type::Comparable;

use strict;

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;

requires 'superclause_comparable';

has_clause 'in',
    v => 2,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, of=>['_same', {req=>1}]}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_comparable('in', $cd);
    };
has_clause 'is',
    v => 2,
    tags       => ['constraint'],
    schema     => ['_same', {req=>1}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_comparable('is', $cd);
    };

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-20'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.912'; # VERSION

1;
# ABSTRACT: Comparable type role

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Type::Comparable - Comparable type role

=head1 VERSION

This document describes version 0.912 of Data::Sah::Type::Comparable (from Perl distribution Data-Sah), released on 2022-08-20.

=head1 DESCRIPTION

Role consumer must provide method C<superclause_comparable> which will be given
normal C<%args> given to clause methods, but with extra key C<-which> (either
C<in>, C<is>).

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
