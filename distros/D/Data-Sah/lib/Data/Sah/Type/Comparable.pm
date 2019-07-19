package Data::Sah::Type::Comparable;

our $DATE = '2019-07-19'; # DATE
our $VERSION = '0.897'; # VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;

requires 'superclause_comparable';

has_clause 'in',
    v => 2,
    tags       => ['constraint'],
    schema     => ['array', {req=>1, of=>['_same', {req=>1}, {}]}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_comparable('in', $cd);
    };
has_clause 'is',
    v => 2,
    tags       => ['constraint'],
    schema     => ['_same', {req=>1}, {}],
    allow_expr => 1,
    code       => sub {
        my ($self, $cd) = @_;
        $self->superclause_comparable('is', $cd);
    };

1;
# ABSTRACT: Comparable type role

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Type::Comparable - Comparable type role

=head1 VERSION

This document describes version 0.897 of Data::Sah::Type::Comparable (from Perl distribution Data-Sah), released on 2019-07-19.

=head1 DESCRIPTION

Role consumer must provide method C<superclause_comparable> which will be given
normal C<%args> given to clause methods, but with extra key C<-which> (either
C<in>, C<is>).

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
