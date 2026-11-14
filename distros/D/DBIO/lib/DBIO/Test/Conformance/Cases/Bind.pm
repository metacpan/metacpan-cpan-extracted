package DBIO::Test::Conformance::Cases::Bind;
# ABSTRACT: The shared Bind cases every DBIO driver answers

use strict;
use warnings;

our $VERSION = '0.900005';

use DBIO::Util ();


my $id = sub { +{ data_type => 'integer', is_nullable => 0 } };

# the table most cases bind into: a key and one nullable column of a base type,
# or varchar(n) for a short string a case searches by value
my $val = sub {
  my ($type, %extra) = @_;
  return {
    name => 'Val', table => 'val',
    columns => [
      id => $id->(),
      v  => { data_type => $type, is_nullable => 1, %extra },
    ],
    primary_key => [ 'id' ],
  };
};

my $ALL = [qw(create find search update)];

# $n characters A..Z, a different run for a different seed
my $text = sub {
  my ($n, $seed) = @_;
  return join '', map { chr(65 + (($_ * 7 + $seed) % 26)) } 0 .. $n - 1;
};

# $n bytes, every value of 0..255 in a fixed order
my $bytes = sub {
  my ($n) = @_;
  return join '', map { chr(($_ * 31 + 7) % 256) } 0 .. $n - 1;
};

my @CASES = (

  {
    name  => 'bind-empty-string',
    since => 1,
    subject => { source => 'Val', column => 's' },
    input => { sources => [ {
      name => 'Val', table => 'val',
      columns => [
        id => $id->(),
        s  => { data_type => 'varchar', size => 20, is_nullable => 1 },
        n  => { data_type => 'integer', is_nullable => 1 },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { bind_roundtrip => { source => 'Val', column => 's', values => [ '' ], ops => $ALL } },
      { rejects => { source => 'Val', create => { id => 9000, n => '' } } },
    ],
  },

  {
    name  => 'bind-digit-string-leading-zero',
    since => 1,
    subject => { source => 'Val', column => 'v' },
    input => { sources => [ $val->('varchar', size => 20) ] },
    expect => [
      { bind_roundtrip => { source => 'Val', column => 'v',
                            values => [ '01234', '007' ], ops => $ALL } },
      # the same values once more, each after a statement that bound an integer
      { bind_roundtrip => { source => 'Val', column => 'v',
                            values => [ '01234', '007' ], ops => [ 'int_first', @$ALL ] } },
    ],
  },

  {
    name  => 'bind-integer-string-in-expression',
    since => 1,
    subject => { source => 'Val', column => 'v' },
    input => { sources => [ $val->('varchar', size => 20) ] },
    expect => [
      # numerically equal, textually different: found only as the application wrote it
      { bind_roundtrip => { source => 'Val', column => 'v',
                            values => [ '5', '5.0', '05', '1e2', '100', '-0', '0' ],
                            ops => $ALL } },
    ],
  },

  {
    name  => 'bind-long-string',
    since => 1,
    subject => { source => 'Val', column => 'v' },
    input => { sources => [ $val->('text') ] },
    expect => [
      { bind_roundtrip => { source => 'Val', column => 'v',
                            values => [ map { $text->($_, $_) } 4001, 8001, 32769, 70000 ],
                            ops => $ALL } },
    ],
  },

  {
    name  => 'bind-non-ascii',
    since => 1,
    subject => { source => 'Val', column => 'v' },
    input => { sources => [ $val->('text') ] },
    expect => [
      { bind_roundtrip => { source => 'Val', column => 'v',
                            values => [
                              "\x{fc}", "\x{20ac}", "\x{65e5}",
                              "Gr\x{fc}\x{df}e \x{20ac}",
                              "\x{65e5}\x{672c}\x{8a9e}",
                              ( "Gr\x{fc}\x{df}e \x{20ac}" x 715 ),
                              ( "\x{65e5}\x{672c}\x{8a9e}" x 1667 ),
                            ],
                            ops => $ALL } },
    ],
  },

  {
    name  => 'bind-binary',
    since => 1,
    subject => { source => 'Val', column => 'v' },
    input => { sources => [ $val->('blob') ] },
    expect => [
      { bind_roundtrip => { source => 'Val', column => 'v',
                            values => [ join('', map { chr } 0 .. 255), $bytes->(9000) ],
                            ops => $ALL } },
    ],
  },

  {
    name  => 'bind-lob-empty-and-large',
    since => 1,
    subject => { source => 'Lob', column => 't' },
    input => { sources => [ {
      name => 'Lob', table => 'lob',
      columns => [
        id => $id->(),
        t  => { data_type => 'text', is_nullable => 1 },
        b  => { data_type => 'blob', is_nullable => 1 },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      # a LOB is not searched by value on most engines: create, read back, update
      { bind_roundtrip => { source => 'Lob', column => 't',
                            values => [ '', $text->(100000, 3) ], ops => [qw(create update)] } },
      { bind_roundtrip => { source => 'Lob', column => 'b',
                            values => [ '', $bytes->(100000) ], ops => [qw(create update)] } },
    ],
  },

  {
    name  => 'bind-lob-row-operations',
    since => 1,
    subject => { source => 'Doc', column => 'body' },
    input => { sources => [ {
      name => 'Doc', table => 'doc',
      columns => [
        id    => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
        label => { data_type => 'text', is_nullable => 1 },
        body  => { data_type => 'blob', is_nullable => 1 },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { bind_lob_ops => { source => 'Doc', column => 'body', label_column => 'label',
                          value => $bytes->(20000) } },
    ],
  },

  {
    name  => 'bind-question-mark-in-literal',
    since => 1,
    subject => { source => 'Note', column => 'txt' },
    input => { sources => [ {
      name => 'Note', table => 'note',
      columns => [
        id  => $id->(),
        txt => { data_type => 'varchar', size => 20, is_nullable => 1 },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      # a ? in a string literal and in a comment stays; the one real bind lands
      { bind_literal => { source => 'Note', column => 'txt',
                          create => { id => 1, txt => 'x' }, value => 'x', other => 'y',
                          literal => q{{{txt}} = ? AND 'a?b' = 'a?b' /* is this a ? */} } },
    ],
  },

  {
    name  => 'bind-numeric-exact',
    since => 1,
    subject => { source => 'Num', column => 'v' },
    input => { sources => [ {
      name => 'Num', table => 'num',
      columns => [
        id => $id->(),
        v  => { data_type => 'numeric', size => [ 20, 4 ], is_nullable => 1 },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { bind_roundtrip => { source => 'Num', column => 'v',
                            values => [ '1234567890123456.7890', '-1234567890123456.7890',
                                        '0.0001' ],
                            ops => $ALL } },
    ],
  },

);

sub cases {
  return DBIO::Util::deep_copy([ @CASES ]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Conformance::Cases::Bind - The shared Bind cases every DBIO driver answers

=head1 VERSION

version 0.900005

=head1 DESCRIPTION

The Bind list of L<DBIO::Test::Conformance> (ADR 0060): ten cases, B1 to B10
of the ADR's first case list (B9 without its dollar-quoted half), as plain Perl
data. A case is one column declaration, the values that go through it and the
operations they go through; what is observable is that every value comes back
as the application wrote it. It holds no SQL and no driver name.

A case is a hash:

  {
    name    => 'bind-long-string',                # stable id, bind- prefix
    since   => 1,                                 # table version that added it
    subject => { source => 'Val', column => 'v' },
    input   => { sources => [ { ... } ] },
    expect  => [ { bind_roundtrip => { ... } }, ... ],
  }

C<input> is a DDL-style declaration (L<DBIO::Test::Conformance/Input>) and
uses the base types of L<DBIO::Schema::Type>, and C<varchar> with a C<size>
for a bounded string (C<text> is a LOB on some servers, which C<=> cannot
compare). C<expect> uses the
expectation kinds C<bind_roundtrip>, C<bind_lob_ops> and C<bind_literal>
(L<DBIO::Test::Conformance/Expectations>) and, for B1, C<rejects>. Every
operation goes through the runner's data seams, so an async transport can run
the list (L<DBIO::Test::Conformance/Running a list over an async transport>).

Values that do not fit a literal -- 4 001 to 70 000 characters, every byte
value, non-ASCII text -- are built here as Perl expressions. The order is the
order of the ADR appendix. Names never change once published; a case that
turns out wrong is replaced by a new one with a higher C<since>.

=head2 Not in the list

=over 4

=item the dollar-quoted half of B9

C<$$ ... ? ... $$> is PostgreSQL syntax; the generic half (a C<?> in a string
literal and in a comment, next to a real bind) is C<bind-question-mark-in-literal>.
The dollar-quoted body is a driver-local case of dbio-postgresql and the
dists that ride on it.

=item the bigint half of B10

C<9223372036854775807> needs a 64-bit integer type, and the base types
have only C<integer>. The exact C<numeric(20,4)> half is
C<bind-numeric-exact>.

=item the float without a column in B3

A float bound to no column has no declaration to carry it; the integer-string
half is C<bind-integer-string-in-expression>.

=back

=head1 METHODS

=head2 cases

  my $cases = DBIO::Test::Conformance::Cases::Bind->cases;

An arrayref of the cases. It is a deep copy: a caller cannot damage the next
run's table.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
