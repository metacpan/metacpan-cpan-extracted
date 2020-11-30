use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Result;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0108';

use parent 'DBIx::Class::Candy';
use String::CamelCase;

use experimental qw/signatures/;

sub base {
    (my $base = caller(2)) =~ s{::Schema::Result::.*$}{};

    return $_[1] || "${base}::Schema::Result";
}
sub autotable    { 1 }
sub perl_version { 20 }
sub experimental { [ ] }

sub gen_table($self, $resultclass, $version) {
    $resultclass =~ s{^.*::Schema::Result::}{};
    $resultclass =~ s{::}{__}g;
    $resultclass = String::CamelCase::decamelize($resultclass);

    return $resultclass;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Result - Short intro

=head1 VERSION

Version 0.0108, released 2020-11-29.

=head1 SOURCE

L<https://github.com/Csson/p5-DBIx-Class-Smooth>

=head1 HOMEPAGE

L<https://metacpan.org/release/DBIx-Class-Smooth>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
