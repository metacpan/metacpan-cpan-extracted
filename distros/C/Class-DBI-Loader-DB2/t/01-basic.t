use strict;
use Test::More;

# my $HAVE_TP = eval { require Time::Piece::DB2 };

plan tests => 3;

use Class::DBI::Loader;
use Class::DBI::DB2;
# use DBI;

print STDERR "\n";

package Foo;

use base qw(Class::DBI::DB2);

# Find a test database to use.

my $schema = $ENV{DBD_DB2_SCHEMA} || read_input("please specify the writable db schema");
my $db     = $ENV{DBD_DB2_DBNAME} || read_input("please specify the writable db name");
my $user   = $ENV{DBD_DB2_USER}   || read_input("please specify the DB2 username to use");
my $pass   = $ENV{DBD_DB2_PASSWD} || read_input("please specify the DB2 password to use");
my $table    = $ENV{DBD_DB2_TABLE}  || read_input("please specify a DB2 table name to create/test/drop");
my $tbl = $schema .".".$table;
my $dsn = "dbi:DB2:$db";

__PACKAGE__->set_db( Main => $dsn, $user, $pass, 
#    { AutoCommit => 1, PrintError => 0, RaiseError => 1, }
);
__PACKAGE__->table($tbl);
__PACKAGE__->drop_table;
__PACKAGE__->create_table(q{
   id     INTEGER     NOT NULL,
   foo    VARCHAR(10),
   bar    VARCHAR(10),
   mydate DATE,
   PRIMARY KEY(id) 
});

sub read_input
{
	my $prompt = shift;
	print STDERR "$prompt: ";
	my $value = <STDIN>;
	chomp $value;
	return $value;
}

END { __PACKAGE__->drop_table }

package main;

my @dat = qw(foo bar baz);
my $lt = '2004-06-21';
my $id=0; my @AoH;
foreach my $dat (@dat) {
  my %row = ( id     => $id, 
              foo    => $dat[$id], 
              bar    => 'bar'.$id, 
              mydate => $lt );
  $id++;
  push @AoH, { %row };
}

    my $loader = Class::DBI::Loader->new(
       dsn => $dsn, 
       user => $user, 
       password => $pass,
    );
    $tbl = uc($tbl);
    my $subclass = lc($tbl);
    $subclass =~ s/_(\w)/ucfirst($1)/eg;
    my $class = ucfirst($subclass);

    is($loader->find_class($tbl), $class);
    my $class1 = $loader->find_class($tbl);

    $class1->create( $_ ) foreach ( @AoH );

    my $obj = $class1->retrieve(1);
    is($obj->id, 1);
    is($obj->foo, "bar");
