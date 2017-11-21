package Catmandu::Importer::DBI;

use Catmandu::Sane;
use DBI;
use Moo;

our $VERSION = '0.0701';

with 'Catmandu::Importer';

has dsn => (is => 'ro', required => 1);
has user     => (is => 'ro');
has password => (is => 'ro');
has query    => (is => 'ro', required => 1);
has dbh =>
    (is => 'ro', init_arg => undef, lazy => 1, builder => '_build_dbh',);
has sth =>
    (is => 'ro', init_arg => undef, lazy => 1, builder => '_build_sth',);

sub _build_dbh {
    my $self = $_[0];
    DBI->connect($self->dsn, $self->user, $self->password);
}

sub _build_sth {
    my $self = $_[0];
    my $sth  = $self->dbh->prepare($self->query);
    $sth->execute;
    $sth;
}

sub generator {
    my ($self) = @_;

    return sub {
        $self->sth->fetchrow_hashref();
        }
}

sub DESTROY {
    my ($self) = @_;
    $self->sth->finish;
    $self->dbh->disconnect;
}

=head1 NAME

Catmandu::Importer::DBI - Catmandu module to import data from any DBI source

=head1 SYNOPSIS

 # From the command line 

 $ catmandu convert DBI --dsn dbi:mysql:foobar --user foo --password bar --query "select * from table"

 # From Perl code

 use Catmandu;

 my %attrs = (
        dsn => 'dbi:mysql:foobar' ,
        user => 'foo' ,
        password => 'bar' ,
        query => 'select * from table'
 );

 my $importer = Catmandu->importer('DBI',%attrs);

 # Optional set extra parameters on the database handle
 # $importer->dbh->{LongReadLen} = 1024 * 64;

 $importer->each(sub {
	my $row_hash = shift;
	...
 });

=head1 DESCRIPTION

This L<Catmandu::Importer> can be used to access data stored in a relational database.
Given a database handle and a SQL query an export of hits will be exported.

=head1 CONFIGURATION

=over

=item dsn

Required. The connection parameters to the database. See L<DBI> for more information.

Examples:
    
      dbi:mysql:foobar   <= a local mysql database 'foobar'
      dbi:Pg:dbname=foobar;host=myserver.org;port=5432 <= a remote PostGres database
      dbi:SQLite:mydb.sqlite <= a local SQLLite file based database mydb.sqlite
      dbi:Oracle:host=myserver.org;sid=data01 <= a remote Oracle database

Drivers for each database need to be available on your computer. Install then with:

    cpanm DBD::mysql
    cpanm DBD::Pg
    cpanm DBD::SQLite
    cpanm DBD::Oracle

=item user

Optional. A user name to connect to the database

=item password

Optional. A password for connecting to the database

=item query

Required. An SQL query to be executed against the datbase. 

=back

=head1 SEE ALSO

L<Catmandu>, L<Catmandu::Importer> , L<Catmandu::Store::DBI>

=cut

1;
