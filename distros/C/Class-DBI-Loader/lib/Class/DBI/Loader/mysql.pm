package Class::DBI::Loader::mysql;

use strict;
use base 'Class::DBI::Loader::Generic';
use vars '$VERSION';
use DBI;
use Carp;
use Class::DBI;
require Class::DBI::mysql;
require Class::DBI::Loader::Generic;

$VERSION = '0.30';

=head1 NAME

Class::DBI::Loader::mysql - Class::DBI::Loader mysql Implementation.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  # $loader is a Class::DBI::Loader::mysql
  my $loader = Class::DBI::Loader->new(
    dsn       => "dbi:mysql:dbname",
    user      => "root",
    password  => "",
    namespace => "Data",
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

See L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>.

=cut

sub _db_class { return 'Class::DBI::mysql' }

# Very experimental and untested!
sub _relationships {
    my $self   = shift;
    my @tables = $self->tables;
    my $dbh    = $self->find_class( $tables[0] )->db_Main;
    my $dsn    = $self->{_datasource}[0];
    my %conn   =
      $dsn =~ m/^dbi:\w+:([\w=]+)/i
      && index( $1, '=' ) >= 0
      ? split( /[=;]/, $1 )
      : ( database => $1 );
    my $dbname = $conn{database} || $conn{dbname} || $conn{db};
    die("Can't figure out the table name automatically.") if !$dbname;
    my $quoter = $dbh->get_info(29);
    my $is_mysql5 = $dbh->get_info(18) =~ /^5./;

    foreach my $table (@tables) {
        if ( $is_mysql5 ) {
            my $query = qq(
                SELECT column_name,
                       referenced_table_name
                  FROM information_schema.key_column_usage
                 WHERE referenced_table_name IS NOT NULL
                   AND table_schema = ?
                   AND table_name = ?
            );
            my $sth = $dbh->prepare($query)
                or die("Cannot get table information: $table");
            $sth->execute($dbname, $table);
            while ( my $data = $sth->fetchrow_hashref ) {
                eval { $self->_has_a_many( $table, $data->{column_name}, $data->{referenced_table_name} ) };
                warn qq/\# has_a_many failed "$@"\n\n/ if $@ && $self->debug;
            }
            $sth->finish;
        } else {
            my $query = "SHOW TABLE STATUS FROM $dbname LIKE '$table'";
            my $sth   = $dbh->prepare($query)
              or die("Cannot get table status: $table");
            $sth->execute;
            my $comment = $sth->fetchrow_hashref->{comment};
            $comment =~ s/$quoter//g if ($quoter);
            while ( $comment =~ m!\(`?(\w+)`?\)\sREFER\s`?\w+/(\w+)`?\(`?\w+`?\)!g ) {
                eval { $self->_has_a_many( $table, $1, $2 ) };
                warn qq/\# has_a_many failed "$@"\n\n/ if $@ && $self->debug;
            }
            $sth->finish;
        }
    }
}

sub _tables {
    my $self = shift;
    my $dbh = DBI->connect( @{ $self->{_datasource} } ) or croak($DBI::errstr);
    my @tables;
    foreach my $table ( $dbh->tables ) {
        if(my $catalog_sep = quotemeta($dbh->get_info(41))) {
          $table = (split($catalog_sep, $table))[-1]
            if $table =~ m/$catalog_sep/;
        }
        my $quoter = $dbh->get_info(29);
        $table =~ s/$quoter//g if ($quoter);
        push @tables, $1
          if $table =~ /\A(\w+)\z/;
    }
    $dbh->disconnect;
    return @tables;
}

=head1 SEE ALSO

L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>

=cut

1;
