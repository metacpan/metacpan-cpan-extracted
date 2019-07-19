package Data::Sah::Type::Sortable;

our $DATE = '2019-07-19'; # DATE
our $VERSION = '0.897'; # VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;

requires 'superclause_sortable';

has_clause 'min',
    v => 2,
    tags       => ['constraint'],
    schema     => ['_same', {req=>1}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('min', $cd);
    },
    ;
has_clause 'xmin',
    v => 2,
    tags       => ['constraint'],
    schema     => ['_same', {req=>1}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('xmin', $cd);
    },
    ;
has_clause 'max',
    v => 2,
    prio       => 51,
    tags       => ['constraint'],
    schema     => ['_same', {req=>1}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('max', $cd);
    },
    ;
has_clause 'xmax',
    v => 2,
    prio       => 51,
    tags       => ['constraint'],
    schema     => ['_same', {req=>1}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('xmax', $cd);
    },
    ;
has_clause 'between',
    v => 2,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, len=>2, elems=>[
        ['_same', {req=>1}, {}],
        ['_same', {req=>1}, {}],
    ]}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('between', $cd);
    },
    ;
has_clause 'xbetween',
    v => 2,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, len=>2, elems=>[
        ['_same', {req=>1}, {}],
        ['_same', {req=>1}, {}],
    ]}, {}],
    allow_expr => 1,
    code => sub {
        my ($self, $cd) = @_;
        $self->superclause_sortable('xbetween', $cd);
    },
    ;

1;
# ABSTRACT: Role for sortable types

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Type::Sortable - Role for sortable types

=head1 VERSION

This document describes version 0.897 of Data::Sah::Type::Sortable (from Perl distribution Data-Sah), released on 2019-07-19.

=head1 DESCRIPTION

Role consumer must provide method C<superclause_sortable> which will receive the
same C<%args> as clause methods, but with additional key: C<-which> (either
C<min>, C<max>, C<xmin>, C<xmax>, C<between>, C<xbetween>).

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
