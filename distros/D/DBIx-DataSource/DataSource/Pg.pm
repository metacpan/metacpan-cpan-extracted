package DBIx::DataSource::Pg;

use strict;
use vars qw($VERSION @ISA);
use DBIx::DataSource::Driver;
@ISA = qw( DBIx::DataSource::Driver );

$VERSION = '0.01';

=head1 NAME

DBIx::DataSource::Pg - PostgreSQL driver for DBIx::DataSource

=head1 SYNOPSIS

  use DBIx::DataSource;

  use DBIx::DataSource qw( create_database drop_database );

  create_database( "dbi:Pg:dbname=$dbname", $username, $password )
    or warn $DBIx::DataSource::errstr;

  create_database( "dbi:Pg:dbname=$dbname;host=$host;port=$port",
                   $username, $password )
    or warn $DBIx::DataSource::errstr;

  drop_database( "dbi:Pg:dbname=$dbname", $username, $password )
    or warn $DBIx::DataSource::errstr;

  drop_database( "dbi:Pg:dbname=$dbname;host=$host;port=$port",
                  $username, $password )
    or warn $DBIx::DataSource::errstr;

=head1 DESCRIPTION

This is the PostgresSQL driver for DBIx::DataSource.

=cut

sub parse_dsn {
  my( $class, $action, $dsn ) = @_;
  $dsn =~ s/^(dbi:(\w*?)(?:\((.*?)\))?:)//i #nicked from DBI->connect
                        or '' =~ /()/; # ensure $1 etc are empty if match fails
  my $prefix = $1 or die "can't parse data source: $dsn";

  my $database;
  if ( $dsn =~ s/(^|[;:])dbname=([^=:;]+)([;:]|$)/$1dbname=template1$3/ ) {
    $database = $2;
  } else {
    die "can't parse data source: $prefix$dsn";
  }

  ( "$prefix$dsn", "\U$action\E DATABASE $database" );
}

=head1 AUTHOR

Ivan Kohler <ivan-dbix-datasource@420.am>

=head1 COPYRIGHT

Copyright (c) 2000 Ivan Kohler
Copyright (c) 2000 Mail Abuse Prevention System LLC
All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

=head1 SEE ALSO

L<DBIx::DataSource::Driver>, L<DBIx::DataSource>, L<DBD::Pg>, L<DBI>

=cut 

1;

