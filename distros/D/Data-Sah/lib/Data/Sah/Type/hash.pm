package Data::Sah::Type::hash;

use strict;

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
    schema     => ['hash' => {req=>1, values => ['sah::schema', {req=>1}]}],
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
        keys   => ['re', {req=>1}],
        values => ['sah::schema', {req=>1}],
    }],
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
    schema     => ['array', {req=>1, of=>['str', {req=>1}]}],
    allow_expr => 1,
    ;
has_clause_alias req_keys => 'req_all_keys';
has_clause_alias req_keys => 'req_all';

has_clause "allowed_keys",
    v => 2,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, of=>['str', {req=>1}]}],
    allow_expr => 1,
    ;

has_clause "allowed_keys_re",
    v => 2,
    prio       => 51,
    tags       => ['constraint'],
    schema     => ['re', {req=>1}],
    allow_expr => 1,
    ;

has_clause "forbidden_keys",
    v => 2,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, of=>['str', {req=>1}]}],
    allow_expr => 1,
    ;

has_clause "forbidden_keys_re",
    v => 2,
    prio       => 51,
    tags       => ['constraint'],
    schema     => ['re', {req=>1}],
    allow_expr => 1,
    ;

has_clause "choose_one_key",
    v => 2,
    prio       => 50,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, of=>['str', {req=>1}], min_len=>1}],
    allow_expr => 0, # for now
    ;
has_clause_alias choose_one_key => 'choose_one';

has_clause "choose_all_keys",
    v => 2,
    prio       => 50,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, of=>['str', {req=>1}], min_len=>1}],
    allow_expr => 0, # for now
    ;
has_clause_alias choose_all_keys => 'choose_all';

has_clause "req_one_key",
    v => 2,
    prio       => 50,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, of=>['str', {req=>1}], min_len=>1}],
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
            [array => {req=>1, of=>['str', {req=>1}], min_len=>1}], # keys
        ],
    }],
    allow_expr => 0, # for now
    ;
has_clause_alias req_some_keys => 'req_some';

# for now we only support the first argument as str, not array[str]
my $sch_dep = ['array', {
    req => 1,
    elems => [
        ['str', {req=>1}],
        ['array', {of=>['str', {req=>1}]}],
    ],
}];

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

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-20'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.912'; # VERSION

1;
# ABSTRACT: hash type

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Type::hash - hash type

=head1 VERSION

This document describes version 0.912 of Data::Sah::Type::hash (from Perl distribution Data-Sah), released on 2022-08-20.

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
