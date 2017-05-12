package Class::DBI::Loader::Pg;

use strict;
use base 'Class::DBI::Loader::Generic';
use vars '$VERSION';
use DBI;
use Carp;

require Class::DBI::Pg;
require Class::DBI::Loader::Generic;

$VERSION = '0.30';

=head1 NAME

Class::DBI::Loader::Pg - Class::DBI::Loader Postgres Implementation.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  # $loader is a Class::DBI::Loader::Pg
  my $loader = Class::DBI::Loader->new(
    dsn       => "dbi:Pg:dbname=dbname",
    user      => "postgres",
    password  => "",
    namespace => "Data",
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

See L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>.

=cut

sub _db_class { return 'Class::DBI::Pg' }

sub _tables {
    my $self = shift;
    my $dbh = DBI->connect( @{ $self->{_datasource} } ) or croak($DBI::errstr);

    # we do this check here because we don't really want to include this as
    # a pre-requisite in the Makefile.PL for all those non-Pg users
    my $sth = $dbh->prepare("SELECT version()");
    $sth->execute();
    my($vstr) = $sth->fetchrow_array();
    $sth->finish;

    my($pg_version) = $vstr =~ /^PostgreSQL ([\d\.]{3})/;
    if ($pg_version >= 8 && $Class::DBI::Pg::VERSION < 0.07) {
        die "Class::DBI::Pg $Class::DBI::Pg::VERSION does not support PostgreSQL > 8.x";
    }

    my @tables = ( $DBD::Pg::VERSION >= 1.31 ) ?
        $dbh->tables( undef, "public", "", "table",
            { noprefix => 1, pg_noprefix => 1 } ) :
        $dbh->tables;
    $dbh->disconnect;
    return @tables;
}

=head1 SEE ALSO

L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>

=cut

1;
