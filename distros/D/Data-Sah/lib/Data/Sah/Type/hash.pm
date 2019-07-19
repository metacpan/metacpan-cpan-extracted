package Data::Sah::Type::hash;

our $DATE = '2019-07-19'; # DATE
our $VERSION = '0.897'; # VERSION

use Data::Sah::Util::Role 'has_clause', 'has_clause_alias';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::HasElems';

has_clause_alias each_elem => 'of';

has_clause_alias each_index => 'each_key';
has_clause_alias each_elem => 'each_value';
has_clause_alias check_each_index => 'check_each_key';
has_clause_alias check_each_elem => 'check_each_value';

has_clause "keys",
    v => 2,
    tags       => ['constraint'],
    schema     => ['hash' => {req=>1, values => ['sah::schema', {req=>1}, {}]}, {}],
    inspect_elem => 1,
    subschema  => sub { values %{ $_[0] } },
    allow_expr => 0,
    attrs      => {
        restrict => {
            schema     => [bool => default=>1],
            allow_expr => 0, # TODO
        },
        create_default => {
            schema     => [bool => default=>1],
            allow_expr => 0, # TODO
        },
    },
    ;

has_clause "re_keys",
    v => 2,
    prio       => 51,
    tags       => ['constraint'],
    schema     => ['hash' => {
        req=>1,
        keys   => ['re', {req=>1}, {}],
        values => ['sah::schema', {req=>1}, {}],
    }, {}],
    inspect_elem => 1,
    subschema  => sub { values %{ $_[0] } },
    allow_expr => 0,
    attrs      => {
        restrict => {
            schema     => [bool => default=>1],
            allow_expr => 0, # TODO
        },
    },
    ;

has_clause "req_keys",
    v => 2,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, of=>['str', {req=>1}, {}]}, {}],
    allow_expr => 1,
    ;
has_clause_alias req_keys => 'req_all_keys';
has_clause_alias req_keys => 'req_all';

has_clause "allowed_keys",
    v => 2,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, of=>['str', {req=>1}, {}]}, {}],
    allow_expr => 1,
    ;

has_clause "allowed_keys_re",
    v => 2,
    prio       => 51,
    tags       => ['constraint'],
    schema     => ['re', {req=>1}, {}],
    allow_expr => 1,
    ;

has_clause "forbidden_keys",
    v => 2,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, of=>['str', {req=>1}, {}]}, {}],
    allow_expr => 1,
    ;

has_clause "forbidden_keys_re",
    v => 2,
    prio       => 51,
    tags       => ['constraint'],
    schema     => ['re', {req=>1}, {}],
    allow_expr => 1,
    ;

has_clause "choose_one_key",
    v => 2,
    prio       => 50,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, of=>['str', {req=>1}, {}], min_len=>1}, {}],
    allow_expr => 0, # for now
    ;
has_clause_alias choose_one_key => 'choose_one';

has_clause "choose_all_keys",
    v => 2,
    prio       => 50,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, of=>['str', {req=>1}, {}], min_len=>1}, {}],
    allow_expr => 0, # for now
    ;
has_clause_alias choose_all_keys => 'choose_all';

has_clause "req_one_key",
    v => 2,
    prio       => 50,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, of=>['str', {req=>1}, {}], min_len=>1}, {}],
    allow_expr => 0, # for now
    ;
has_clause_alias req_one_key => 'req_one';

has_clause "req_some_keys",
    v => 2,
    prio       => 50,
    tags       => ['constraint'],
    schema     => ['array', {
        req => 1,
        len => 3,
        elems => [
            [int => {req=>1, min=>0}], # min
            [int => {req=>1, min=>0}], # max
            [array => {req=>1, of=>['str', {req=>1}, {}], min_len=>1}, {}], # keys
        ],
    }, {}],
    allow_expr => 0, # for now
    ;
has_clause_alias req_some_keys => 'req_some';

# for now we only support the first argument as str, not array[str]
my $sch_dep = ['array', {
    req => 1,
    elems => [
        ['str', {req=>1}, {}],
        ['array', {of=>['str', {req=>1}, {}]}, {}],
    ],
}, {}];

has_clause "dep_any",
    v => 2,
    prio       => 50,
    tags       => ['constraint'],
    schema     => $sch_dep,
    allow_expr => 0, # for now
    ;

has_clause "dep_all",
    v => 2,
    prio       => 50,
    tags       => ['constraint'],
    schema     => $sch_dep,
    allow_expr => 0, # for now
    ;

has_clause "req_dep_any",
    v => 2,
    prio       => 50,
    tags       => ['constraint'],
    schema     => $sch_dep,
    allow_expr => 0, # for now
    ;

has_clause "req_dep_all",
    v => 2,
    prio       => 50,
    tags       => ['constraint'],
    schema     => $sch_dep,
    allow_expr => 0, # for now
    ;

# prop_alias indices => 'keys'

# prop_alias elems => 'values'

1;
# ABSTRACT: hash type

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Type::hash - hash type

=head1 VERSION

This document describes version 0.897 of Data::Sah::Type::hash (from Perl distribution Data-Sah), released on 2019-07-19.

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
