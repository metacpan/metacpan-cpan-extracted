package DBIO::Informix::ColumnDef;
# ABSTRACT: Render a single Informix column definition fragment

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';
our @EXPORT_OK = qw(column_def_sql);

use DBIO::Informix::Util qw(_quote_ident);
use DBIO::Informix::Types qw(ddl_type);


# Character types whose plain-scalar default must be quoted.
# BOOLEAN ('t') and DATE ('01/02/2020') literals are quoted too: unquoted they
# are syntax errors (measured, Informix 15.0.1, karr k20).
my %CHAR_TYPE = map { $_ => 1 } qw(char varchar nchar nvarchar lvarchar text boolean date);

sub column_def_sql {
  my (%spec) = @_;

  # Informix SERIAL is itself a type -- never combine it with a base type,
  # and a serial column carries no DEFAULT.
  # SERIAL8 and BIGSERIAL are such types as well and stay what they are.
  my $serial = $spec{is_auto_increment};
  my $type   = $serial
    ? (lc($spec{type} // '') =~ /\A(serial8|bigserial)\z/ ? uc $1 : 'SERIAL')
    : ($spec{type} // 'VARCHAR(255)');

  # an introspected column carries its size apart from the type name; a bare
  # VARCHAR is VARCHAR(1) and a bare DECIMAL a floating DECIMAL(16)
  $type = ddl_type($type, $spec{size})
    if !$serial && defined $spec{size} && $type !~ /\(/;

  my $def = sprintf '%s %s', _quote_ident($spec{name}), $type;

  if (!$serial && defined $spec{default_value}) {
    $def .= ' DEFAULT ' . _default_fragment($spec{type}, $spec{default_value});
  }

  $def .= ' NOT NULL' if $spec{not_null};

  return $def;
}

# Render a default value: SCALAR ref => literal SQL; character-typed plain
# scalar => quoted; everything else => raw.
sub _default_fragment {
  my ($type, $dv) = @_;
  return _expression_default($$dv) if ref $dv eq 'SCALAR';

  my $base = lc($type // '');
  $base =~ s/\(.*//;            # varchar(255) -> varchar
  $base =~ s/\s.*//;            # datetime year to second -> datetime
  return $dv unless $CHAR_TYPE{$base};
  (my $quoted = $dv) =~ s/'/''/g;
  return "'$quoted'";
}

# The expression defaults of the ANSI spelling, in the words Informix takes
# (CURRENT_TIMESTAMP is a syntax error there). Anything else is the user's
# SQL and stays as written.
sub _expression_default {
  my ($sql) = @_;
  (my $e = $sql) =~ s/\A\s+|\s+\z//g;
  return 'CURRENT YEAR TO FRACTION(5)' if $e =~ /\A(?:current_timestamp|now\(\)|localtimestamp)(?:\(\d?\))?\z/i;
  return 'TODAY'                       if $e =~ /\Acurrent_date\z/i;
  return 'USER'                        if $e =~ /\A(?:current_user|session_user)\z/i;
  return $sql;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::ColumnDef - Render a single Informix column definition fragment

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Informix::ColumnDef> owns the grammar of a single Informix column
definition -- the C<< name type [DEFAULT ...] [NOT NULL] >> fragment shared
by C<CREATE TABLE>, C<ALTER TABLE ADD (...)> and C<ALTER TABLE MODIFY>.

Before this module the same fragment was assembled independently in
L<DBIO::Informix::DDL>, L<DBIO::Informix::Diff::Table> and
L<DBIO::Informix::Diff::Column>, each with its own subtle drift (default
quoting, C<SERIAL> placement). Those three call sites now delegate here so
the dialect lives in one place.

Type normalization stays with the caller: the diff path already carries a
full SQL type string (C<varchar(255)>), whereas the DDL path resolves a
logical type via C<_informix_column_type>. This module only assembles the
fragment from an already-resolved type.

    use DBIO::Informix::ColumnDef qw(column_def_sql);

    my $sql = column_def_sql(
        name              => 'name',
        type              => 'varchar(255)',
        not_null          => 1,
        default_value     => \'today',     # SCALAR ref => literal SQL
        is_auto_increment => 0,
    );
    # => name varchar(255) DEFAULT today NOT NULL

=head1 METHODS

=head2 column_def_sql

    my $fragment = column_def_sql(%spec);

Returns the column-definition fragment (no leading indent, no trailing
comma). C<%spec> keys:

=over 4

=item * C<name> -- column name, quoted as an identifier.

=item * C<type> -- already-resolved SQL type string. Ignored when
C<is_auto_increment> is set (Informix C<SERIAL> is itself a type).

=item * C<not_null> -- truthy emits C<NOT NULL>, after any C<DEFAULT>: Informix takes the DEFAULT clause before the column constraint (HCL OneDB/Informix SQL Syntax, ALTER TABLE ADD/MODIFY, ids_sqs_0077 / ids_sqs_0078, example C<DEFAULT 1 NOT NULL>; live unmeasured).

=item * C<default_value> -- a SCALAR ref is emitted as literal SQL (the ANSI
C<CURRENT_TIMESTAMP>, C<NOW()>, C<CURRENT_DATE> and C<CURRENT_USER> become
C<CURRENT YEAR TO FRACTION(5)>, C<TODAY> and C<USER>); a plain
scalar is quoted (a C<'> doubled) only for character types; C<undef> emits no default. A
C<SERIAL> column never emits a default.

=item * C<size> -- the size of the introspected model (a number, or
C<[precision, scale]>), added to a C<type> that does not carry one itself
(see L<DBIO::Informix::Types/ddl_type>).

=item * C<is_auto_increment> -- truthy makes the type C<SERIAL>, or stays
C<SERIAL8> / C<BIGSERIAL> when C<type> is one of them.

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
