use strict;
use Test::More;

my $HAVE_TP = eval { require Time::Piece::DB2 };

plan tests => 14;

use Class::DBI::DB2;
use DBI;

print STDERR "\n";

package Foo;

use base qw(Class::DBI::DB2);

# Find a test database to use.

my $schema = $ENV{DBD_DB2_SCHEMA} || read_input("please specify the writable db schema");
my $db     = $ENV{DBD_DB2_DBNAME} || read_input("please specify the writable db name");
my $user   = $ENV{DBD_DB2_USER}   || read_input("please specify the DB2 username to use");
my $pass   = $ENV{DBD_DB2_PASSWD} || read_input("please specify the DB2 password to use");
my $table    = $ENV{DBD_DB2_TABLE}  || read_input("please specify a DB2 table name to create/test/drop");
my $tbl = $schema ."\.".$table;

__PACKAGE__->set_db( Main => "dbi:DB2:$db", $user, $pass, 
#    { AutoCommit => 1, PrintError => 0, RaiseError => 1, }
);
__PACKAGE__->table($tbl);
__PACKAGE__->drop_table;
__PACKAGE__->create_table(q{
   id     INTEGER     NOT NULL,
   foo    VARCHAR(10) NOT NULL,
   bar    VARCHAR(10),
   mydate DATE,
   PRIMARY KEY(id) 
});
__PACKAGE__->set_up_table;
__PACKAGE__->autoinflate(dates => 'Time::Piece') if $HAVE_TP;

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

can_ok Foo => "id";

my @dat = qw(foo bar baz);
my $lt = '2004-06-21';
if ($HAVE_TP) { use Time::Piece; $lt = localtime; }
my $id=0; my @AoH;
foreach my $dat (@dat) {
  my %row = ( id     => $id, 
              foo    => $dat[$id], 
              bar    => 'bar'.$id, 
              mydate => $lt );
  $id++;
  push @AoH, { %row };
}
Foo->create( $_ ) foreach ( @AoH );

is( Foo->retrieve_all, 3 );

is(Foo->table, $schema . "." . $table);
is(Foo->columns, 4);

is(Foo->column_type("Foo"),"VARCHAR");
is(Foo->column_no("Foo"),1);
is(Foo->column_nulls("Foo"),"N");
is(Foo->column_nulls("Id"),"N");

my @columns = sort Foo->columns('All');
is_deeply(\@columns, [sort qw(id foo bar mydate)]);

my $obj = Foo->retrieve(2);
is( $obj->FOO, 'baz' );
is($obj->BAR, 'bar2');
my ($obj2) = Foo->search( foo => 'foo' );
is( $obj2->ID, 0 );

SKIP: { 
	skip "Need Time::Piece::DB2", 2 unless $HAVE_TP;
	isa_ok $obj2->MYDATE => "Time::Piece", "MYDATE";
	is $obj2->MYDATE->ymd, Time::Piece->new->ymd, "From today";
} 
