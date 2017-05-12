package DBIx::Class::Loader::DB2;

use strict;
use base 'DBIx::Class::Loader::Generic';
use Carp;

=head1 NAME

DBIx::Class::Loader::DB2 - DBIx::Class::Loader DB2 Implementation.

=head1 SYNOPSIS

  use DBIx::Class::Loader;

  # $loader is a DBIx::Class::Loader::DB2
  my $loader = DBIx::Class::Loader->new(
    dsn       => "dbi:DB2:dbname",
    user      => "myuser",
    password  => "",
    namespace => "Data",
    schema    => "MYSCHEMA",
    dropschema  => 0,
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

See L<DBIx::Class::Loader>.

=head1 KNOW ISSUES

L<DBIx::Class::Loader::DB2> will not pass test suites (nor work quite
completely for applications) with L<DBIx::Class> versions less than
0.05.  This is because prior to that release, there was no
L<DBIx::Class::PK::Auto::DB2>.  As long as you don't use any
auto-incrementing primary keys, things should be sane though.

=cut

sub _db_classes {
    return qw/DBIx::Class::PK::Auto::DB2/;
}

sub _tables {
    my $self = shift;
    my %args = @_; 
    my $schema = uc ($args{schema} || '');
    my $dbh = $self->{storage}->dbh;

    # this is split out to avoid version parsing errors...
    my $is_dbd_db2_gte_114 = ( $DBD::DB2::VERSION >= 1.14 );
    my @tables = $is_dbd_db2_gte_114 ? 
    $dbh->tables( { TABLE_SCHEM => '%', TABLE_TYPE => 'TABLE,VIEW' } )
        : $dbh->tables;

    # People who use table or schema names that aren't identifiers deserve
    # what they get.  Still, FIXME?
    s/\"//g for @tables;
    @tables = grep {!/^SYSIBM\./ and !/^SYSCAT\./ and !/^SYSSTAT\./} @tables;
    @tables = grep {/^$schema\./} @tables if($schema);
    return @tables;
}

sub _table_info {
    my ( $self, $table ) = @_;
#    $|=1;
#    print "_table_info($table)\n";
    my ($schema, $tabname) = split /\./, $table, 2;
    # print "Schema: $schema, Table: $tabname\n";
    
    # FIXME: Horribly inefficient and just plain evil. (JMM)
    my $dbh = $self->{storage}->dbh;
    $dbh->{RaiseError} = 1;

    my $sth = $dbh->prepare(<<'SQL') or die;
SELECT c.COLNAME
FROM SYSCAT.COLUMNS as c
WHERE c.TABSCHEMA = ? and c.TABNAME = ?
SQL

    $sth->execute($schema, $tabname) or die;
    my @cols = map { lc $_ } map { @$_ } @{$sth->fetchall_arrayref};
    $sth->finish;

    $sth = $dbh->prepare(<<'SQL') or die;
SELECT kcu.COLNAME
FROM SYSCAT.TABCONST as tc
JOIN SYSCAT.KEYCOLUSE as kcu ON tc.constname = kcu.constname
WHERE tc.TABSCHEMA = ? and tc.TABNAME = ? and tc.TYPE = 'P'
SQL

    $sth->execute($schema, $tabname) or die;

    my @pri = map { lc $_ } map { @$_ } @{$sth->fetchall_arrayref};

    $sth->finish;
    
    return ( \@cols, \@pri );
}

# Find and setup relationships
sub _relationships {
    my $self = shift;

    my $dbh = $self->{storage}->dbh;
    $dbh->{RaiseError} = 1;
    my $sth = $dbh->prepare(<<'SQL') or die;
SELECT SR.COLCOUNT, SR.REFTBNAME, SR.PKCOLNAMES, SR.FKCOLNAMES
FROM SYSIBM.SYSRELS SR WHERE SR.TBNAME = ?
SQL

    foreach my $table ( $self->tables ) {
        if ($sth->execute(uc $table)) {
            while(my $res = $sth->fetchrow_arrayref()) {
                my ($colcount, $other, $other_column, $column) =
                    map { $_=lc; s/^\s+//; s/\s+$//; $_; } @$res;
                next if $colcount != 1; # XXX no multi-col FK support yet
                eval { $self->_belongs_to_many( $table, $column, $other,
                  $other_column ) };
                warn qq/\# belongs_to_many failed "$@"\n\n/
                  if $@ && $self->debug;
            }
        }
    }

    $sth->finish;
}


=head1 SEE ALSO

L<DBIx::Class::Loader>

=cut

1;
