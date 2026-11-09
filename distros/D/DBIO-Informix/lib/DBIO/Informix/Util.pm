package DBIO::Informix::Util;
# ABSTRACT: Identifier quoting shared by the Informix DDL and diff writers

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';
our @EXPORT_OK = qw(_quote_ident);


sub _quote_ident {
  my ($name) = @_;
  return $name if $name =~ /\A[a-z_][a-z0-9_]*\z/;
  $name =~ s/"/""/g;
  return qq{"$name"};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Util - Identifier quoting shared by the Informix DDL and diff writers

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Informix folds an unquoted identifier to lower case (with C<DELIMIDENT> set,
which L<DBIO::Informix::Storage> does at connect, a double-quoted one is kept
as written). A name that is not all lower case therefore has to be quoted, or
the object the DDL creates is not the one the ORM selects from. This is the
one place that decides.

=head1 METHODS

=head2 _quote_ident

    _quote_ident('users');       # users
    _quote_ident('MixedCase');   # "MixedCase"
    _quote_ident('odd "c"');     # "odd ""c"""

A name of lower case letters, digits and underscores that does not start with
a digit stays bare; anything else is double-quoted with an embedded C<">
doubled.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
