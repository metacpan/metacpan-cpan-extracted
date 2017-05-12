package Class::DBI::Loader::SQLite;

use strict;
use base 'Class::DBI::Loader::Generic';
use vars '$VERSION';
use Text::Balanced qw( extract_bracketed );
use DBI;
use Carp;
require Class::DBI::SQLite;
require Class::DBI::Loader::Generic;

$VERSION = '0.30';

=head1 NAME

Class::DBI::Loader::SQLite - Class::DBI::Loader SQLite Implementation.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  # $loader is a Class::DBI::Loader::SQLite
  my $loader = Class::DBI::Loader->new(
    dsn       => "dbi:SQLite:dbname=/path/to/dbfile",
    namespace => "Data",
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

Multi-column primary keys are supported. It's also fine to define multi-column
foreign keys, but they will be ignored because L<Class::DBI> does not support them.

See L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>.

=cut

sub _db_class { return 'Class::DBI::SQLite' }

sub _relationships {
    my $self = shift;
    foreach my $table ( $self->tables ) {

        my $dbh = $self->find_class($table)->db_Main;
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
            if ( $col =~ /^(\w+).*REFERENCES\s+(\w+)/i ) {
                chomp $col;
                warn qq/\# Found foreign key definition "$col"\n\n/
                  if $self->debug;
                eval { $self->_has_a_many( $table, $1, $2 ) };
                warn qq/\# has_a_many failed "$@"\n\n/ if $@ && $self->debug;
            }
        }
    }
}

sub _tables {
    my $self = shift;
    my $dbh  = DBI->connect( @{ $self->{_datasource} } ) or croak($DBI::errstr);
    my $sth  = $dbh->prepare("SELECT * FROM sqlite_master");
    $sth->execute;
    my @tables;
    while ( my $row = $sth->fetchrow_hashref ) {
        next unless lc( $row->{type} ) eq 'table';
        push @tables, $row->{tbl_name};
    }
    $sth->finish;
    $dbh->disconnect;
    return @tables;
}

=head1 SEE ALSO

L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>

=cut

1;
