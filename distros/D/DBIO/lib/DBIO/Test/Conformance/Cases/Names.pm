package DBIO::Test::Conformance::Cases::Names;
# ABSTRACT: The shared cases for names a driver writes as identifiers: schema, extension, load library

use strict;
use warnings;

our $VERSION = '0.900005';

use DBIO::Util ();


my @NAMES = (
  [ plain     => 'a_b'     ],
  [ quote     => 'a"b'     ],
  [ semicolon => 'a;b'     ],
  [ blank     => 'a b'     ],
  [ backslash => 'a\\b'    ],
  [ newline   => "a\nb"    ],
);

my @CASES = map {
  my $kind = $_;
  map {
    +{
      name  => "name-$kind-$_->[0]",
      since => 1,
      input => { kind => $kind, name => $_->[1] },
    };
  } @NAMES;
} qw(schema extension library);

sub cases { return DBIO::Util::deep_copy(\@CASES) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Conformance::Cases::Names - The shared cases for names a driver writes as identifiers: schema, extension, load library

=head1 VERSION

version 0.900005

=head1 DESCRIPTION

The Names list of L<DBIO::Test::Conformance> (ADR 0060, ADR 0077): a schema
name (the connect key C<schema>), the name of a database extension and the
name of a library an extension loads are B<identifiers>. A driver writes each
of them into a statement only through its identifier quoting (or a bind), or
refuses it with a L<DBIO::Exception>. These cases hand the driver, per kind, a
plain name and five names a naive statement builder cannot take: a double
quote, a semicolon, a blank, a backslash and a line break.

A case is a hash:

  {
    name  => 'name-schema-quote',      # stable id, name- prefix
    since => 1,                        # table version that added it
    input => { kind => 'schema', name => 'a"b' },
  }

C<kind> is C<schema>, C<extension> or C<library>. There is no C<expect>: the
two acceptable answers are the same for every case (L<DBIO::Test::Conformance/Names>).
A driver answers a kind through the capability
L<DBIO::Test::Conformance/conformance_name_kinds>; a kind it does not declare
is not applicable.

Names never change once published; a case that turns out wrong is replaced by
a new one with a higher C<since>.

=head1 METHODS

=head2 cases

  my $cases = DBIO::Test::Conformance::Cases::Names->cases;

An arrayref of the cases, a deep copy.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
