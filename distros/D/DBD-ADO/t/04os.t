#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use DBD::ADO::Const();

my @SchemaEnums = keys %{DBD::ADO::Const->Enums->{SchemaEnum}};

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 4 + @SchemaEnums;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('OpenSchema tests');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
   $dbh->{RaiseError} = 1;
   $dbh->{PrintError} = 0;
pass('Database connection created');

#eval { $dbh->ado_open_schema('adBadCallOpenSchema') }; # DBI 1.37++
eval { $dbh->func('adBadCallOpenSchema','OpenSchema') or die 'Error'};
#eval { $dbh->func('adBadCallOpenSchema','OpenSchema') }; # DBI 1.41++
ok( $@,'Call to OpenSchema() with bad argument');

$dbh->{Warn} = 0;

for my $ad ( sort @SchemaEnums ) {
  my $sth = eval { $dbh->func( $ad,'OpenSchema') };
  SKIP: {
    skip("$ad: not supported by Provider", 1 ) unless defined $sth;
    pass("pass $ad");
    print "#\t", DBI::neat_list( $sth->{NAME} ), "\n";
#   while( my $row = $sth->fetch ) {
#     print "#\t", DBI::neat_list( $row ), "\n";
#   }
    $sth = undef;
  }
}

ok( $dbh->disconnect,'Disconnect');
