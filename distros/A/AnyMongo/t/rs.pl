use strict;
use warnings;
use AnyMongo;
use boolean;
use Data::Dumper;
use Devel::Peek;
use Data::Dump;

my $m = AnyMongo->new_connection(host => "mongodb://localhost:27018", find_master => 1);

my $db = $m->get_database("admin");
my $c = $db->get_collection("bar");

while (true) {
#   print "finding...";
   eval {
       $c->find_one();
   };
   if ($@) {
       print "find_one error:".$@;
   }
   else {
       if ($m->{master_id}){
           print "connected to: ".$m->{master_id}."\n";
       }
       else {
           print "no master\n";
       }
   }
   sleep 1;
}
__END__

=head1 NAME

rs.pl - Replica set testing script.

=head1 SYNOPSIS

    perl -I lib -I blib/lib -I blib/arch t/rs.pl
  
=head1 DESCRIPTION

 First, setup replica test enviroment.

=head3 start 3 mongod nodes

DB=/bak/data/mongodb
mongod --fork -v  --noprealloc --replSet rs1 --port 27017 --dbpath "$DB/rs0" --rest
mongod --fork -v  --noprealloc --replSet rs1 --port 27018 --dbpath "$DB/rs1" --rest
mongod --fork -v  --noprealloc --replSet rs1 --port 27019 --dbpath "$DB/rs2" --rest

=head3  config rs

ns-mbp:any-mongo night$ mongo localhost

MongoDB shell version: 1.6.0
connecting to: localhost
> config = {_id: 'rs1', members: [
    {_id: 0, host: 'localhost:27017'},
    {_id: 1, host: 'localhost:27018'},
    {_id: 2, host: 'localhost:27019'}]
}
> rs.initiate(config);
> rs.status()

=head3 Now, test

dzil build
cd AnyMongo-0.02
perl Makefile.PL
make
perl -I lib -I blib/lib -I blib/arch t/rs.pl


* kill some mongod procedure, watching, the driver will try to new master

* kill all mongod

* startup all mongod

now, driver should reconnect success.

=cut