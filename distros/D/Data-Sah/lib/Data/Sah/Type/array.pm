package Data::Sah::Type::array;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use Data::Sah::Util::Role 'has_clause', 'has_clause_alias';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::HasElems';

has_clause 'elems',
    v => 2,
    tags       => ['constraint'],
    schema     => ['array' => {req=>1, of=>['sah::schema', {req=>1}, {}]}, {}],
    inspect_elem => 1,
    allow_expr => 0,
    subschema  => sub { @{ $_[0] } },
    attrs      => {
        create_default => {
            schema     => [bool => {default=>1}, {}],
            allow_expr => 0, # TODO
        },
    },
    ;
has_clause_alias each_elem => 'of';

1;
# ABSTRACT: array type

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Type::array - array type

=head1 VERSION

This document describes version 0.896 of Data::Sah::Type::array (from Perl distribution Data-Sah), released on 2019-07-04.

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
