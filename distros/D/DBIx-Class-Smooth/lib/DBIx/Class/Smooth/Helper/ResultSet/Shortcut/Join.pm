use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::ResultSet::Shortcut::Join;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0107';

use parent 'DBIx::Class::Smooth::ResultSetBase';
use Carp qw/confess/;
use experimental qw/signatures postderef/;

sub join($self, @args) {

    if(!scalar @args) {
        return $self;
    }
    elsif(scalar @args >= 2) {
        die 'Too many args';
    }
    return $self->search(undef, { join => $args[0]});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Helper::ResultSet::Shortcut::Join - Short intro

=head1 VERSION

Version 0.0107, released 2020-10-28.

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
