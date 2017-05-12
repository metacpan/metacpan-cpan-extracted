package DBIx::InsertHash;
our $VERSION = '0.011';


=head1 NAME

DBIx::InsertHash - insert/update a database record from a hash

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use DBIx::InsertHash;

    # insert
    DBIx::InsertHash->insert({USERNAME => 'foo',
                              PASSWORD => 'bar',
                             }, 'table', $dbh);

    # update
    DBIx::InsertHash->update({PASSWORD => 'foobar'},
                             [12],'USERID = ?',
                             'table', $dbh);

    # constructor usage
    my $dbix = DBIx::InsertHash->new(quote => 1,
                                     dbh   => $dbh,
                                     table => 'table',
                                     where => 'USERID = ?',
                                    );
    $dbix->insert($hash);
    $dbix->update($hash, [12]);

=cut

use strict;
use warnings;

use Carp qw(carp croak);

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(quote quote_char quote_func
                             dbh table where
                            ));

=head1 DESCRIPTION

If you have data in a hash (which keys are matching the column names) and
want to insert it in a database, then this is the right module for you.
It frees you from having to construct the SQL statement.

It really only does a simple insert (or update) from a hash into a single
table. For anything beyond I suggest a ORM (object-relational mapper),
like L<Rose::DB::Object> or L<DBIx::Class>.

=head1 INTERFACE

=head2 new

Constructor (optional). Only needed to store default values or set
quoting options.

=over 4

=item quote (BOOL)

Turn quoting of column names on (off by default). This switch affects
all column names (see L<quote_func> below to only quote specific names).

If you use MySQL, quoting is recommended. It is needed when column names
clash with reserved words.

=item quote_char (STRING)

Quoting character/string (default is backtick).

=item qoute_func (CODEREF)

This function is given the column name as first (and only) parameter. It
has to return a boolean, indicating if the column has to be quoted.

The following example uses L<SQL::ReservedWords>:

    my $quote = sub { SQL::ReservedWords->is_reserved($_[0]) };

    my $dbix = DBIx::InsertHash->new(quote_func => $quote);

    $dbix->insert(...);

=back

=cut

sub new {
    my ($class, %arg) = @_;
    $arg{quote_char} ||= '`';

    return $class->SUPER::new(\%arg);
}

=head2 insert

Insert hash in database. Returns L<last_insert_id|DBI/last_insert_id>.

=over 4

=item data (HASHREF)

Row data. The keys have to match with the column names of your table.
This parameter is mandatory. If an empty hashref is given, no record is
inserted and a warning is given.

=item table (STRING)

Table name. If this parameter is missing, the object default (see L<new>
is used). Otherwise it dies.

=item dbh (OBJECT)

DBI database handle (you have to L<connect|DBI/connect> yourself). If
this parameter is missing, the object default (see L<new>) is used).
Otherwise it dies.

=back

=cut

sub insert {
    my ($self, $data, $table, $dbh) = @_;

    # object defaults
    if (ref $self) {
        $table ||= $self->table;
        $dbh   ||= $self->dbh;
    }

    # warnings/errors
    unless (%$data) {
        carp 'No data (empty hash)';
        return;
    }
    croak 'No table name' unless $table;
    croak 'No DBI handle' unless $dbh;

    # sort by hash key (predictable results)
    my @column = sort keys %$data;
    my @value  = map { $data->{$_} } @column;

    # quote column names?
    if (ref $self and ($self->quote or $self->quote_func)) {
        foreach my $col (@column) {
            next unless $self->quote or $self->quote_func->($col);
            $col = $self->quote_char . $col . $self->quote_char;
        }
    }

    my $sql = 'INSERT INTO '.$table.' (';
    $sql .= join(', ', @column).') VALUES (';
    $sql .= join(', ', ('?') x (scalar @column)).')';

    $dbh->do($sql, {}, @value);

    return $dbh->last_insert_id(undef, undef, $table, undef);
}

=head2 update

Update record from hash. Returns L<do|DBI/do>.

=over 4

=item data (HASHREF)

Row data. The keys have to match with the column names of your table.
This parameter is mandatory. If an empty hashref is given, no record is
inserted and a warning is given.

=item bind_values (ARRAYREF)

L<Bind values|DBI/Placeholders_and_Bind_Values> for the WHERE clause. If
you do not use or need them, just pass a false value (C<undef> or empty
string) or an empty arrayref. This parameter is optional and has no object
defaults.

=item where (STRING)

Where clause (with optional placeholders C<?>). If this parameter is
missing, the object default (see L<new>) is used. Otherwise it dies.

=item table (STRING)

Table name. If this parameter is missing, the object default (see L<new>
is used). Otherwise it dies.

=item dbh (OBJECT)

DBI database handle (you have to L<connect|DBI/connect> yourself). If
this parameter is missing, the object default (see L<new>) is used).
Otherwise it dies.

=back

=cut

sub update {
    my ($self, $data, $vars, $where, $table, $dbh) = @_;
    my @vars = ($vars ? @$vars : ());

    # object defaults
    if (ref $self) {
        $where ||= $self->where;
        $table ||= $self->table;
        $dbh   ||= $self->dbh;
    }

    unless (%$data) {
        carp 'No data (empty hash)';
        return;
    }
    croak 'No where clause' unless $where;
    croak 'No table name'   unless $table;
    croak 'No DBI handle'   unless $dbh;

    # sort by hash key (predictable results)
    my @column = sort keys %$data;
    my @value  = map { $data->{$_} } @column;

    # quote column names?
    if (ref $self and ($self->quote or $self->quote_func)) {
        foreach my $col (@column) {
            next unless $self->quote or $self->quote_func->($col);
            $col = $self->quote_char . $col . $self->quote_char;
        }
    }

    my $sql = 'UPDATE '.$table.' SET ';
    $sql .= join(', ', map { "$_ = ?" } @column).' WHERE '.$where;

    return $dbh->do($sql, {}, @value, @vars);
}


1;

__END__

=pod

=head1 REPOSITORY

    http://github.com/uwe/dbix-inserthash/tree/master

=head1 AUTHOR

Uwe Voelker, <uwe.voelker@gmx.de>

=cut