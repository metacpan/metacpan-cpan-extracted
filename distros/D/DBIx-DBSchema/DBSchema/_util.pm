# internal utility subroutines used by multiple classes

package DBIx::DBSchema::_util;

use strict;
use vars qw(@ISA @EXPORT_OK);
use Exporter;
use Carp qw(confess);
use DBI;

@ISA = qw(Exporter);
@EXPORT_OK = qw( _load_driver _dbh _parse_opt );

sub _load_driver {
  my($dbh) = @_;
  my $driver;
  if ( ref($dbh) ) {
    $driver = $dbh->{Driver}->{Name};
  } else {
    $dbh =~ s/^dbi:(\w*?)(?:\((.*?)\))?://i #nicked from DBI->connect
                        or '' =~ /()/; # ensure $1 etc are empty if match fails
    $driver = $1 or confess "can't parse data source: $dbh";
  }

  #require "DBIx/DBSchema/DBD/$driver.pm";
  #$driver;
  eval 'require "DBIx/DBSchema/DBD/$driver.pm"' and $driver or die $@;
}

#sub _dbh_or_dbi_connect_args {
sub _dbh {
  my($dbh) = shift;
  my $created_dbh = 0;
  unless ( ref($dbh) || ! @_ ) {
    $dbh = DBI->connect( $dbh, @_ ) or die $DBI::errstr;
    $created_dbh = 1;
  }

  ( $dbh, $created_dbh );
}

sub _parse_opt {
  my $optref = shift;
  if ( ref( $optref->[0] ) eq 'HASH' ) {
    shift @$optref;
  } else {
    {};
  }
}

1;

