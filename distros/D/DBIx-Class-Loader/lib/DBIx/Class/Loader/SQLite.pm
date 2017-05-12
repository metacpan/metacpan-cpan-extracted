package DBIx::Class::Loader::SQLite;

use strict;
use base 'DBIx::Class::Loader::Generic';
use Text::Balanced qw( extract_bracketed );
use Carp;

=head1 NAME

DBIx::Class::Loader::SQLite - DBIx::Class::Loader SQLite Implementation.

=head1 SYNOPSIS

  use DBIx::Class::Loader;

  # $loader is a DBIx::Class::Loader::SQLite
  my $loader = DBIx::Class::Loader->new(
    dsn       => "dbi:SQLite:dbname=/path/to/dbfile",
    namespace => "Data",
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

See L<DBIx::Class::Loader>.

=cut

sub _db_classes {
    return qw/DBIx::Class::PK::Auto::SQLite/;
}

sub _relationships {
    my $self = shift;
    foreach my $table ( $self->tables ) {

        my $dbh = $self->{storage}->dbh;
        my $sth = $dbh->prepare(<<"");
SELECT sql FROM sqlite_master WHERE tbl_name = ?

        $sth->execute($table);
        my ($sql) = $sth->fetchrow_array;
        $sth->finish;

        # Cut "CREATE TABLE ( )" blabla...
        $sql =~ /^[\w\s]+\((.*)\)$/si;
        my $cols = $1;

        # strip single-line comments
        $cols =~ s/\-\-.*\n/\n/g;

        # temporarily replace any commas inside parens,
        # so we don't incorrectly split on them below
        my $cols_no_bracketed_commas = $cols;
        while ( my $extracted =
            ( extract_bracketed( $cols, "()", "[^(]*" ) )[0] )
        {
            my $replacement = $extracted;
            $replacement              =~ s/,/--comma--/g;
            $replacement              =~ s/^\(//;
            $replacement              =~ s/\)$//;
            $cols_no_bracketed_commas =~ s/$extracted/$replacement/m;
        }

        # Split column definitions
        for my $col ( split /,/, $cols_no_bracketed_commas ) {

            # put the paren-bracketed commas back, to help
            # find multi-col fks below
            $col =~ s/\-\-comma\-\-/,/g;

            # CDBI doesn't have built-in support multi-col fks, so ignore them
            next if $col =~ s/^\s*FOREIGN\s+KEY\s*//i && $col =~ /^\([^,)]+,/;

            # Strip punctuations around key and table names
            $col =~ s/[()\[\]'"]/ /g;
            $col =~ s/^\s+//gs;

            # Grab reference
            if ( $col =~ /^(\w+).*REFERENCES\s+(\w+)\s*(\w+)?/i ) {
                chomp $col;
                warn qq/\# Found foreign key definition "$col"\n\n/
                  if $self->debug;
                eval { $self->_belongs_to_many( $table, $1, $2, $3 ) };
                warn qq/\# belongs_to_many failed "$@"\n\n/
                  if $@ && $self->debug;
            }
        }
    }
}

sub _tables {
    my $self = shift;
    my $dbh  = $self->{storage}->dbh;
    my $sth  = $dbh->prepare("SELECT * FROM sqlite_master");
    $sth->execute;
    my @tables;
    while ( my $row = $sth->fetchrow_hashref ) {
        next unless lc( $row->{type} ) eq 'table';
        push @tables, $row->{tbl_name};
    }
    return @tables;
}

sub _table_info {
    my ( $self, $table ) = @_;

    # find all columns.
    my $dbh = $self->{storage}->dbh;
    my $sth = $dbh->prepare("PRAGMA table_info('$table')");
    $sth->execute();
    my @columns;
    while ( my $row = $sth->fetchrow_hashref ) {
        push @columns, $row->{name};
    }
    $sth->finish;

    # find primary key. so complex ;-(
    $sth = $dbh->prepare(<<'SQL');
SELECT sql FROM sqlite_master WHERE tbl_name = ?
SQL
    $sth->execute($table);
    my ($sql) = $sth->fetchrow_array;
    $sth->finish;
    my ($primary) = $sql =~ m/
    (?:\(|\,) # either a ( to start the definition or a , for next
    \s*       # maybe some whitespace
    (\w+)     # the col name
    [^,]*     # anything but the end or a ',' for next column
    PRIMARY\sKEY/sxi;
    my @pks;

    if ($primary) {
        @pks = ($primary);
    }
    else {
        my ($pks) = $sql =~ m/PRIMARY\s+KEY\s*\(\s*([^)]+)\s*\)/i;
        @pks = split( m/\s*\,\s*/, $pks ) if $pks;
    }
    return ( \@columns, \@pks );
}

=head1 SEE ALSO

L<DBIx::Class::Loader>

=cut

1;
