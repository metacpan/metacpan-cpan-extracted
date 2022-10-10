package Data::Sah::Type::HasElems;

use strict;

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;

requires 'superclause_has_elems';

has_clause 'max_len',
    v => 2,
    prio       => 51,
    tags       => ['constraint'],
    schema     => ['int', {min=>0}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('max_len', $cd);
    };

has_clause 'min_len',
    v => 2,
    tags       => ['constraint'],
    schema     => ['int', {min=>0}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('min_len', $cd);
    };

has_clause 'len_between',
    v => 2,
    tags       => ['constraint'],
    schema     => ['array' => {req=>1, len=>2, elems => [
        [int => {req=>1}],
        [int => {req=>1}],
    ]}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len_between', $cd);
    };

has_clause 'len',
    v => 2,
    tags       => ['constraint'],
    schema     => ['int', {min=>0}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('len', $cd);
    };

has_clause 'has',
    v => 2,
    tags       => ['constraint'],
    schema       => ['_same_elem', {req=>1}],
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
    schema     => ['sah::schema', {req=>1}],
    subschema  => sub { $_[0] },
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('each_index', $cd);
    };

has_clause 'each_elem',
    v => 2,
    tags       => ['constraint'],
    schema     => ['sah::schema', {req=>1}],
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
    schema     => ['sah::schema', {req=>1}],
    subschema  => sub { $_[0] },
    allow_expr => 0,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_has_elems('check_each_index', $cd);
    };

has_clause 'check_each_elem',
    v => 2,
    tags       => ['constraint'],
    schema     => ['sah::schema', {req=>1}],
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
    schema     => ['bool', {}],
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
    schema     => ['sah::schema', {req=>1}],
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

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-30'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.913'; # VERSION

1;
# ABSTRACT: HasElems role

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Type::HasElems - HasElems role

=head1 VERSION

This document describes version 0.913 of Data::Sah::Type::HasElems (from Perl distribution Data-Sah), released on 2022-09-30.

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
