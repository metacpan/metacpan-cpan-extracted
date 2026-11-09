package DBIO::MySQL::Identifier;
# ABSTRACT: MySQL/MariaDB identifier quoting for generated DDL

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Exception ();
use Exporter 'import';

our @EXPORT_OK = qw(quote_ident check_table_name split_table_name quote_table quote_table_in);



sub quote_ident {
  my ($name) = @_;
  $name =~ s/`/``/g;
  return "`$name`";
}


sub split_table_name {
  my ($name) = @_;
  return (undef, $name) unless defined $name && !ref $name && $name =~ /\./;
  my @parts = split /\./, $name, -1;
  DBIO::Exception->throw("DBIO::MySQL: table '$name' is refused: a table name "
    . 'is table or database.table, with both halves given and one dot')
    unless @parts == 2 && length $parts[0] && length $parts[1];
  return @parts;
}


sub quote_table {
  my ($database, $table) = split_table_name($_[0]);
  return defined $database ? quote_ident($database) . '.' . quote_ident($table) : quote_ident($table);
}


sub quote_table_in {
  my ($database, $table) = @_;
  return defined $database ? quote_ident($database) . '.' . quote_ident($table) : quote_ident($table);
}


sub check_table_name {
  my ($name, $kind) = @_;
  return $name unless defined $name && !ref $name && $name =~ /\./;
  $kind //= 'table';
  if ($kind ne 'table') {
    DBIO::Exception->throw("DBIO::MySQL: $kind '$name' is refused: a name with a "
      . "dot means database.table to MySQL, and creating a $kind in another "
      . "database is not supported. Name the $kind without a dot");
  }
  split_table_name($name);
  return $name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Identifier - MySQL/MariaDB identifier quoting for generated DDL

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Single source of truth for how the name of a database, table, view, column,
index or constraint is written into a DDL statement this driver generates.

MySQL and MariaDB quote an identifier with backticks. A name that is a
reserved word (C<order>, C<key>, C<group>, C<rank>, ...) or that is no plain
word (C<my-col>) is a syntax error without them, and double quotes are no
substitute: unless the session runs in C<ANSI_QUOTES>, C<"my-col"> is a string
literal. That is why core's ANSI helper, C<DBIO::SQL::Util::_quote_ident>,
which leaves a plain name bare and puts any other into double quotes, is not
used by this driver.

The quoting is needed wherever DDL is rendered -- the desired-state DDL
(L<DBIO::MySQL::DDL>), the four diff operations (L<DBIO::MySQL::Diff::Table>,
L<DBIO::MySQL::Diff::Column>, L<DBIO::MySQL::Diff::Index>,
L<DBIO::MySQL::Diff::ForeignKey>) and the temporary database of
L<DBIO::MySQL::Deploy> -- so it lives here once.

Queries are not rendered through this module. L<DBIO::MySQL::SQLMaker> quotes
their identifiers itself, with the same character
(L<DBIO::MySQL::Storage> sets C<sql_quote_char> to a backtick).

=head1 METHODS

=head2 quote_ident

    use DBIO::MySQL::Identifier qw(quote_ident);

    my $sql_name = quote_ident($name);

    quote_ident('users');     # `users`
    quote_ident('order');     # `order`
    quote_ident('my-col');    # `my-col`
    quote_ident('we`ird');    # `we``ird`

Returns C<$name> between backticks, every backtick inside it doubled. That is
all the escaping the server asks for there: neither a quote of either kind nor
a backslash is special between backticks, and backticks quote an identifier
whatever the C<sql_mode> -- C<ANSI_QUOTES> and C<NO_BACKSLASH_ESCAPES> change
nothing about it (checked on MySQL 8.0 and MariaDB 11.8).

Every name is quoted, a plain one as well. Quoting only where it is needed
would take a list of reserved words, and that list differs between MySQL and
MariaDB and grows with their versions (C<rank> and C<groups> became reserved
in MySQL 8.0).

The argument is one identifier. A dot is part of the name and is not read as
the separator of a qualified one: C<quote_ident('db.t')> is the name C<db.t>
and not the table C<t> of the database C<db>. The name of a table of a source
goes through L</quote_table> instead, which splits it at the dot.

=head2 split_table_name

    my ($database, $table) = split_table_name('other.t');   # ('other', 't')
    my ($database, $table) = split_table_name('t');          # (undef, 't')

Splits the name a source gives its table at its dot: C<database.table> to
MySQL. A name without a dot is the table alone. Throws a
L<DBIO::Exception> for a name with more than one dot or with an empty half
(C<.t>, C<db.>), which names nothing.

=head2 quote_table

    quote_table('t');          # `t`
    quote_table('other.t');    # `other`.`t`

The name of a table as DDL writes it: both halves quoted by L</quote_ident>,
the database in front when the name has one (L</split_table_name>).

=head2 quote_table_in

    quote_table_in(undef, 't');      # `t`
    quote_table_in('other', 't');    # `other`.`t`

The table C<$table> as a diff operation writes it: in the database
C<$database> when one is given (the operation belongs to a table of another
database), else as L</quote_ident> writes it. The table is one identifier in
both cases -- a dot in it is part of the name -- because the database is given
apart; this is what tells the table C<other>.C<t> from a table in the current
database that is literally called C<other.t>.

=head2 check_table_name

    check_table_name($name);            # a table
    check_table_name($name, 'view');

Returns C<$name> when it is a name the DDL can write, and throws a
L<DBIO::Exception> when it is not. A table name is C<table> or
C<database.table> (L</split_table_name>): C<< table('db.t') >> and C<< \'db.t'
>> create the table C<t> in the database C<db>, written C<`db`.`t`> as a query
through the SQLMaker reads it. The driver creates no database: whether C<db>
exists is asked of the server by L<DBIO::MySQL::Deploy>, which refuses an
install naming the table and the database when it does not. A view name with a
dot is still refused, as is a name with two dots or an empty half. A name that
is not a plain string (a subquery source) is passed through.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
