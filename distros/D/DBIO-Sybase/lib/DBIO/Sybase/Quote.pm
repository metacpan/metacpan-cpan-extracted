package DBIO::Sybase::Quote;
# ABSTRACT: Quote an identifier the way Sybase ASE reads it

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';
use DBIO::Exception ();
our @EXPORT_OK = qw(quote_ident is_keyword keywords);



our %KEYWORD = map { $_ => 1 } qw(
  add all alter and any arith_overflow as asc at authorization avg begin
  between break browse bulk by called cascade case char_convert check
  checkpoint close clustered coalesce commit compressed compute confirm
  connect constraint continue controlrow convert count count_big create
  current cursor database dbcc deallocate declare decrypt decrypt_default
  default delete desc deterministic disk distinct drop dual_control dummy
  dump else encrypt end endtran errlvl errordata errorexit escape except
  exclusive exec execute exists exit exp_row_size external fetch
  fillfactor for foreign from goto grant group having holdlock identity
  identity_gap identity_insert identity_start if in index inout
  insensitive insert install intersect into is isolation jar join key kill
  level like lineno load lob_compression lock log manage materialized max
  max_rows_per_page min mirror mirrorexit modify national noholdlock
  nonclustered not null nullif numeric_truncation of off offsets on once
  online only open option or order out output over partition perm
  permanent plan prepare primary print privileges proc procedure
  processexit proxy_table public quiesce raiserror read readpast readtext
  reconfigure references release_locks_on_close remove reorg replace
  replication reservepagegap return returns revoke role rollback rowcount
  rows rule save schema scroll select semi_sensitive set setuser shared
  shutdown some statistics stringsize stripe sum syb_identity syb_restree
  syb_terminate table temp temporary textsize to tracefile tran
  transaction trigger truncate tsequal union unique unpartition unsigned
  update use user user_option using values varying view waitfor when where
  while with work writetext xmlextract xmlparse xmltable xmltest
);


sub keywords { sort keys %KEYWORD }



sub is_keyword { exists $KEYWORD{ lc $_[0] } }


sub quote_ident {
  my ($name) = @_;
  DBIO::Exception->throw(sprintf
    q{DBIO::Sybase: cannot write the name '%s' as an identifier: a name starting with # or @ is a temporary table or a variable to ASE, which refuses it as the name of a table, column or index even in brackets (Msg 11717, 16366)},
    $name) if $name =~ /\A[#@]/;
  DBIO::Exception->throw(sprintf
    q{DBIO::Sybase: cannot write the name '%s' as an identifier: ASE reads a dot as owner.name, also inside brackets (Msg 2734), so it cannot be part of a name and a name with a dot is refused},
    $name) if $name =~ /\./;
  return $name if $name =~ /\A[a-z_][a-z0-9_]*\z/i and not is_keyword($name);
  (my $q = $name) =~ s/\]/]]/g;
  return "[$q]";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Quote - Quote an identifier the way Sybase ASE reads it

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The one place where DBIO::Sybase writes an identifier -- table, column, index,
constraint, view -- into DDL (L<DBIO::Sybase::DDL>, the C<DBIO::Sybase::Diff::*>
operations).

A name is written B<bare> when it is a simple identifier (a letter or C<_>, then
letters, digits and C<_>) and no ASE keyword, and in B<square brackets> otherwise:
C<[dummy]>, C<[my table]>. The default is the bare form for the same reason it
was before: a diff and a deployment of the same schema compare by name, and
C<sysobjects> holds the name without its brackets either way.

Brackets and not double quotes: C<"name"> is an identifier only with
C<set quoted_identifier on>, which a login does not have by default, and ASE
answers it with Msg 102 (measured, ASE 16.0 SP02, 2026-10-24). C<[name]> parses
always. A C<]> inside a name is written C<]]> (measured: C<[a]]b]> is the table
C<a]b>, stored without the brackets).

Two kinds of name no quoting reaches, and L</quote_ident> refuses them itself
with a L<DBIO::Exception> naming the name and the reason, instead of passing the
server's error on: a name that starts with C<#> or C<@> (a temporary table or a
variable; the server answers Msg 11717 and 16366 even in brackets), and one with
a dot, which ASE reads as C<owner.name> in brackets too (Msg 2734). The driver
sends no temporary table through here (its temporary database is named by
L<DBIO::Sybase::Deploy> itself).

=head1 METHODS

=head2 keywords

    my @words = keywords();

The list above, sorted, lower case.

=head2 is_keyword

    is_keyword('dummy');    # true

True when the name, in any case, is on the list of words ASE refuses as an
identifier.

=head2 quote_ident

    my $sql = quote_ident($name);

The identifier as it goes into a statement: C<$name> itself if it is simple and
no keyword, otherwise C<[$name]> with every C<]> doubled. Throws a
L<DBIO::Exception> for a name that starts with C<#> or C<@> or contains a dot.

=head1 THE KEYWORD LIST

A word of this list is refused bare as the name of a table, a column, an index
or a constraint (Msg 156, or 102 where the parser meets it before the name):
C<create table dummy (id int)> is C<Msg 156: Incorrect syntax near the keyword
'dummy'>, the case that started it (the table of C<DBIO::Test::Schema::Dummy>).

B<Source: the server's catalog>, C<master..spt_values> rows of C<type = 'W'>,
which ASE 16.0 SP02 PL02 has (218 words, read 2026-10-25). The list is that
catalog plus four words the catalog does not name and a measurement found
refused all the same: C<called> and C<log> as an index name, C<unsigned> as a
column name, C<identity_insert> in all four places. Measured 2026-10-24
(DBD::Sybase 1.27 on FreeTDS 1.3.17) by sending about 600 candidate words --
the Reference Manual's reserved words as remembered, the SQL-92 words, the type
names, the names columns commonly have -- bare as C<CREATE TABLE w>, C<CREATE
TABLE t (w int)>, C<CREATE INDEX w ON t (id)> and C<CREATE TABLE t (id int,
CONSTRAINT w PRIMARY KEY (id))>, and again in brackets where one of them
failed: 215 failed bare, none failed in brackets. Compared with the catalog, 211
of the 215 are in it, and the catalog has seven the measurement did not try
(C<compressed>, C<decrypt>, C<decrypt_default>, C<dual_control>, C<encrypt>,
C<manage>, C<release_locks_on_close>). The words of the manual that ASE accepts
(C<func>, C<new>, C<scrollable>, ...), the type names (C<int>, C<varchar>,
C<text>) and the SQL-92 words (C<left>, C<cast>, C<current_date>) are neither
in the catalog nor on this list, and are written bare.

The list is fixed in the code; the driver does not read the catalog at run
time. F<t/96-quote-ident-live.t> reads it from the server it runs against and
reports both directions of a difference: a catalog word missing here fails the
test, a word here that the catalog lacks is kept and named in the output.

B<Not a guarantee:> a server of another release may have more words, and a word
missing from both the catalog and the measurement is refused by the server with
Msg 156, as it was before this module.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
