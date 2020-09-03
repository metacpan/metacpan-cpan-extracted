use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::ResultSet;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0104';

use parent 'DBIx::Class::Candy::ResultSet';

sub base {
    (my $base = caller(2)) =~ s{^(.*?)::Schema::ResultSet::.*}{$1};

    return $_[1] || "${base}::Schema::ResultSet";
}
sub perl_version { 20 }

sub experimental { [] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::ResultSet - Short intro

=head1 VERSION

Version 0.0104, released 2020-08-30.

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
