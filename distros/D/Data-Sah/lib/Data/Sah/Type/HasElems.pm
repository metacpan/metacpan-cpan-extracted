package Data::Sah::Type::HasElems;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;

requires 'superclause_has_elems';

has_clause 'max_len',
    v => 2,
    prio       => 51,
    tags       => ['constraint'],
    schema     => ['int', {min=>0}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('max_len', $cd);
    };

has_clause 'min_len',
    v => 2,
    tags       => ['constraint'],
    schema     => ['int', {min=>0}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('min_len', $cd);
    };

has_clause 'len_between',
    v => 2,
    tags       => ['constraint'],
    schema     => ['array' => {req=>1, len=>2, elems => [
        [int => {req=>1}, {}],
        [int => {req=>1}, {}],
    ]}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len_between', $cd);
    };

has_clause 'len',
    v => 2,
    tags       => ['constraint'],
    schema     => ['int', {min=>0}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len', $cd);
    };

has_clause 'has',
    v => 2,
    tags       => ['constraint'],
    schema       => ['_same_elem', {req=>1}, {}],
    inspect_elem => 1,
    prio         => 55, # we should wait for clauses like e.g. 'each_elem' to coerce elements
    allow_expr   => 1,
    code         => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('has', $cd);
    };

has_clause 'each_index',
    v => 2,
    tags       => ['constraint'],
    schema     => ['sah::schema', {req=>1}, {}],
    subschema  => sub { $_[0] },
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('each_index', $cd);
    };

has_clause 'each_elem',
    v => 2,
    tags       => ['constraint'],
    schema     => ['sah::schema', {req=>1}, {}],
    inspect_elem => 1,
    subschema  => sub { $_[0] },
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('each_elem', $cd);
    };

has_clause 'check_each_index',
    v => 2,
    tags       => ['constraint'],
    schema     => ['sah::schema', {req=>1}, {}],
    subschema  => sub { $_[0] },
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('check_each_index', $cd);
    };

has_clause 'check_each_elem',
    v => 2,
    tags       => ['constraint'],
    schema     => ['sah::schema', {req=>1}, {}],
    inspect_elem => 1,
    subschema  => sub { $_[0] },
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('check_each_elem', $cd);
    };

has_clause 'uniq',
    v => 2,
    tags       => ['constraint'],
    schema     => ['bool', {}, {}],
    inspect_elem => 1,
    prio         => 55, # we should wait for clauses like e.g. 'each_elem' to coerce elements
    subschema  => sub { $_[0] },
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('uniq', $cd);
    };

has_clause 'exists',
    v => 2,
    tags       => ['constraint'],
    schema     => ['sah::schema', {req=>1}, {}],
    inspect_elem => 1,
    subschema  => sub { $_[0] },
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('exists', $cd);
    };

# has_prop 'len';

# has_prop 'elems';

# has_prop 'indices';

1;
# ABSTRACT: HasElems role

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Type::HasElems - HasElems role

=head1 VERSION

This document describes version 0.896 of Data::Sah::Type::HasElems (from Perl distribution Data-Sah), released on 2019-07-04.

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
