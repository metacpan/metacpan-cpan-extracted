#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use DBI();

my $NUM_MANUFACT = 100;
my $NUM_PRODUCT = 100000;
my $NUM_PEOPLE = 1000;
my $NUM_INVENTORY = 200000;

chdir $Bin;

my $DBFILE = "db/dat.db";
system("rm -rf db") if -d "db";
mkdir "db";

my $dbh = DBI->connect("dbi:SQLite:dbname=$DBFILE","","");

$dbh->do("
CREATE TABLE manufact (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL
)
");

$dbh->do("
CREATE TABLE product (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  manufact INTEGER NOT NULL REFERENCES manufact(id),
  prodno INTEGER NOT NULL
)
");

$dbh->do("
CREATE TABLE person (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL
)
");

$dbh->do("
CREATE TABLE inventory (
  id INTEGER PRIMARY KEY,
  barcode TEXT NOT NULL,
  product INTEGER NOT NULL REFERENCES product(id),
  owner INTEGER NOT NULL REFERENCES person(id),
  date_acquired TEXT,
  date_disposed TEXT
)
");

sub randomAr {
  my $rv='';
  $rv .= (ref($_)) ? $$_[rand @$_] : $_ for @_;
  return join(' ', map { ucfirst($_) } split /\s+/, $rv);
}
my @name1 = qw( qui wa wi whi ea ru ti tri tra uti affe dru dri fru free fra gra gru gree pri hou jou ki lou li la clou cou sou si ste bo phi pa alle an chri jenni ace de app pea lem gla ju ja mu ma ni nu na bra bru cra cru bla blu ble we );
my @name2 = qw( nd st d ve b le ck n la ne fer tone ter on re th ld tine one pe es ss yst nce nor lph ble ther ger gur sh be );
my @companysuffix = ((('') x 10), 'LLC', 'Institute', 'Enterprises');
my @A9 = (('A'..'Z'),(0..9));
sub randomProdNo { my $rv = ''; $rv .= $A9[rand @A9] for 1 .. int(rand(9)) + 3; return $rv; }
$dbh->begin_work();
my $sth;
$sth = $dbh->prepare("INSERT INTO manufact (id, name) VALUES (?,?)");
foreach my $id (1 .. $NUM_MANUFACT) {
  $sth->execute($_, randomAr(\@name1,\@name2,' ',\@companysuffix));
}
$sth  = $dbh->prepare("INSERT INTO product (id, name, manufact, prodno) VALUES (?,?,?,?)");
foreach my $id (1 .. $NUM_PRODUCT) {
  my $manufact_id = int(rand($NUM_MANUFACT)) + 1;
  my $productname = randomAr(\@name1,\@name1,\@name1,\@name2);
  $sth->execute($id, $productname, $manufact_id, randomProdNo());
}
$sth  = $dbh->prepare("INSERT INTO person (id, name, email) VALUES (?,?,?)");
foreach my $id (1 .. $NUM_PEOPLE) {
  my $name = randomAr(\@name1,\@name2,' ',\@name1,\@name1,\@name2);
  my $email = $name; 
  $email =~ s/\s+/\./g;
  my $domain = randomAr(\@name1,\@name2);
  $email .= '@'.$domain.'.com';
  $sth->execute($id, $name, $email);
}

my $lasttime = 999999999;

$sth  = $dbh->prepare("INSERT INTO inventory (id, barcode, product, owner, date_acquired, date_disposed) VALUES (?,?,?,?,?,?)");
foreach my $id (1 .. $NUM_INVENTORY) {
  my $owner_id = int(rand(1000)) + 1;
  my $product_id = int(rand($NUM_PRODUCT)) + 1;
  my $barcode = '345'.sprintf("%03d",$id);
  $lasttime += int(rand(9999)) + 1;
  my @t = localtime($lasttime);
  my $date_acquired = ($t[5] + 1900).'-'.sprintf("%02d", $t[4] + 1).'-'.sprintf("%02d", $t[3]);
  my $date_disposed;
  if (rand(5) > 3) {
    @t = localtime($lasttime + rand(999999));
    $date_disposed = ($t[5] + 1900).'-'.sprintf("%02d", $t[4] + 1).'-'.sprintf("%02d", $t[3]);
  }

  $sth->execute($id, $barcode, $product_id, $owner_id, $date_acquired, $date_disposed);
}

$dbh->do("
CREATE TABLE oq_saved_search (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  uri TEXT NOT NULL,
  oq_title TEXT NOT NULL,
  user_title TEXT NOT NULL,
  params TEXT,
  alert_mask INTEGER NOT NULL DEFAULT 0,
  alert_interval_min INTEGER,
  alert_dow TEXT,
  alert_start_hour INTEGER,
  alert_end_hour INTEGER,
  alert_last_dt DATETIME,
  alert_err TEXT,
  alert_uids TEXT,
  is_default INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT unq_oq_saved_search UNIQUE (user_id,uri,oq_title,user_title)
)");

$dbh->do("
CREATE TABLE oq_autoaction (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uri TEXT NOT NULL,
  oq_title TEXT NOT NULL,
  user_title TEXT NOT NULL,
  params TEXT,
  start_dt DATETIME NOT NULL,
  end_dt   DATETIME,
  repeat_interval_min INTEGER UNSIGNED NOT NULL DEFAULT 1440,
  last_run_dt DATETIME NOT NULL,
  trigger_mask INTEGER UNSIGNED NOT NULL,
  error_txt TEXT
)");


$dbh->do("CREATE INDEX idx_manufact_name ON manufact (name)");
$dbh->do("CREATE INDEX idx_product_name ON product (name)");
$dbh->do("CREATE INDEX idx_product_prodno ON product (prodno)");
$dbh->do("CREATE INDEX idx_product_manufact ON product (manufact)");
$dbh->do("CREATE INDEX idx_inventory_barcode ON inventory(barcode)");
$dbh->do("CREATE INDEX idx_inventory_product ON inventory(product)");
$dbh->do("CREATE INDEX idx_inventory_owner ON inventory(owner)");
$dbh->commit();
$dbh->disconnect();

system("chmod -R ugo+rwX db");
