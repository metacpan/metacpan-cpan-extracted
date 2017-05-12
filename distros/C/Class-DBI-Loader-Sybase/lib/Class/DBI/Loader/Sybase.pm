package Class::DBI::Loader::Sybase;

use strict;
use Class::DBI;
use base 'Class::DBI::Loader::Generic';
use vars '$VERSION';
use DBI;
use Carp;
require Class::DBI::Sybase;
require Class::DBI::Loader::Generic;

$VERSION = '0.02';

=head1 NAME

Class::DBI::Loader::Sybase - Class::DBI::Loader Sybase Implementation.

=head1 SYNOPSIS

  use Class::DBI::Loader;

  # $loader is a Class::DBI::Loader::Sybase
  my $loader = Class::DBI::Loader->new(
    dsn       => "dbi:Sybase:dbname=dbname",
    user      => "sybase",
    password  => "",
    namespace => "Data",
  );
  my $class = $loader->find_class('film'); # $class => Data::Film
  my $obj = $class->retrieve(1);

=head1 DESCRIPTION

See L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>.

=cut

sub _db_class { return 'Class::DBI::Sybase' }

sub _tables {
    my $self = shift;
    my $dbh = DBI->connect( @{ $self->{_datasource} } ) or croak($DBI::errstr);
    my @tables;
    return $dbh->tables( undef, undef, undef, "TABLE" );
}

=head1 SEE ALSO

L<Class::DBI::Loader>, L<Class::DBI::Loader::Generic>

=cut

1;
