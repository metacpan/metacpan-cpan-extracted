package Data::Sah::Type::BaseType;

# why name it BaseType instead of Base? because I'm sick of having 5 files named
# Base.pm in my editor (there would be Type::Base and the various
# Compiler::*::Type::Base).

use 5.010;
use strict;
use warnings;

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
#use Sah::Schema::Common;
#use Sah::Schema::Sah;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-16'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.917'; # VERSION

our $sch_filter_elem = ['any', {of=>[
    ['str', {req=>1}],
    ['array', {req=>1, len=>2, elems=>[ ['str',{req=>1}], ['hash',{req=>1}] ]}],
]}];

requires 'handle_type';

has_clause 'v',
    v => 2,
    prio   => 0,
    tags   => ['meta', 'defhash'],
    schema => ['float'=>{req=>1, is=>1}],
    ;

has_clause 'defhash_v',
    v => 2,
    prio   => 0,
    tags   => ['meta', 'defhash'],
    schema => ['float'=>{req=>1, is=>1}],
    ;

has_clause 'schema_v',
    v => 2,
    prio   => 0,
    tags   => ['meta'],
    schema => ['float'=>{req=>1}],
    ;

has_clause 'base_v',
    v => 2,
    prio   => 0,
    tags   => ['meta'],
    schema => ['float'=>{req=>1}],
    ;

has_clause 'ok',
    v => 2,
    tags       => ['constraint'],
    prio       => 1,
    schema     => ['any', {}],
    allow_expr => 1,
    ;
has_clause 'default',
    v => 2,
    prio       => 1,
    tags       => ['default'],
    schema     => ['any', {}],
    allow_expr => 1,
    attrs      => {
        temp => {
            schema     => [bool => {default=>0}],
            allow_expr => 0,
        },
    },
    ;
has_clause 'prefilters',
    v => 2,
    tags       => ['filter'],
    prio       => 10,
    schema      => ['array' => {of=>$sch_filter_elem}],
    attrs      => {
        temp => {
        },
    }
    ;
has_clause 'default_lang',
    v => 2,
    tags       => ['meta', 'defhash'],
    prio       => 2,
    schema     => ['str'=>{req=>1, default=>'en_US'}],
    ;
has_clause 'name',
    v => 2,
    tags       => ['meta', 'defhash'],
    prio       => 2,
    schema     => ['str', {req=>1}],
    ;
has_clause 'summary',
    v => 2,
    prio       => 2,
    tags       => ['meta', 'defhash'],
    schema     => ['str', {req=>1}],
    ;
has_clause 'description',
    v => 2,
    tags       => ['meta', 'defhash'],
    prio       => 2,
    schema     => ['str', {req=>1}],
    ;
has_clause 'tags',
    v => 2,
    tags       => ['meta', 'defhash'],
    prio       => 2,
    schema     => ['array', {of=>['str', {req=>1}, {}]}],
    ;
has_clause 'req',
    v => 2,
    tags       => ['constraint'],
    prio       => 3,
    schema     => ['bool', {}],
    allow_expr => 1,
    ;
has_clause 'forbidden',
    v => 2,
    tags       => ['constraint'],
    prio       => 3,
    schema     => ['bool', {}],
    allow_expr => 1,
    ;
has_clause 'if',
    v => 2,
    tags       => ['constraint'],
    prio       => 50,
    schema     => ['array', {}], # XXX elems: [str|array|hash, str|array|hash, [ str|array|hash ]]
    allow_expr => 0,
;

#has_clause 'each', tags=>['constraint'];

#has_clause 'check_each', tags=>['constraint'];

#has_clause 'exists', tags=>['constraint'];

#has_clause 'check_exists', tags=>['constraint'];

#has_clause 'check', schema=>['sah::expr',{req=>1},{}], tags=>['constraint'];

has_clause 'clause',
    v => 2,
    tags       => ['constraint'],
    prio       => 50,
    schema     => ['array' => {req=>1, len=>2, elems => [
        ['sah::clname', {req=>1}],
        ['any', {}],
    ]}],
    ;
has_clause 'clset',
    v => 2,
    prio   => 50,
    tags   => ['constraint'],
    schema => ['sah::clset', {req=>1}],
    ;
has_clause 'postfilters',
    v => 2,
    tags       => ['filter'],
    prio       => 90,
    schema     => ['array' => {req=>1, of=>$sch_filter_elem}],
    attrs      => {
    }
    ;
has_clause 'examples',
    v => 2,
    tags       => ['meta'],
    prio       => 99,
    schema     => ['array', {of=>['any', {}]}], # XXX non-hash or defhash with 'value' property specified
    ;
has_clause 'links',
    v => 2,
    tags       => ['meta'],
    prio       => 99,
    schema     => ['array', {of=>['hash', {}]}], # XXX defhash, with at leasts 'url' property specified
    ;

1;
# ABSTRACT: Base type

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Type::BaseType - Base type

=head1 VERSION

This document describes version 0.917 of Data::Sah::Type::BaseType (from Perl distribution Data-Sah), released on 2024-02-16.

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

This software is copyright (c) 2024, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
