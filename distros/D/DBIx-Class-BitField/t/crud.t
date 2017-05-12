use Test::More tests => 227;

use lib qw(t/lib);

use Schema;
my $schema = Schema->connect;
my $rs = $schema->resultset('Item');

my @status = qw(status1 status2 status3);


ok($rs->create({id => 1, bitfield => 1}));
  
is($rs->find(1)->status1, 1);

foreach my $i (2..10) {
  my $status = $status[int(rand()*3)];
  ok($rs->create({id => $i, bitfield => $status}));
  is($rs->find($i)->$status, 1);
}

foreach my $i (11..20) {
  my $status = $status[int(rand()*3)];
  $status = [$status, $status[int(rand()*3)]] ;
  ok($rs->create({id => $i, bitfield => $status}));
  foreach my $s (@{$status}) {
    is($rs->find($i)->$s, 1);
  }
}

eval { $rs->create({id => 11, bitfield => 'foobar'}) };
  
ok($@, 'throws error '.$@);


ok(my $row = $rs->create({id => 21, status1 => 1, status3 => 1, status_status1 => 1, status_status2 => 1}));
  
is($row->_bitfield, 5);

is($row->__bitfield2, 3);

foreach my $i (1..10) {
  my $status = $status[int(rand()*3)];
  ok($rs->find($i)->update({bitfield => $status}));  
  is($rs->find($i)->$status, 1);
}

foreach my $i (11..20) {
  my $status = $status[int(rand()*3)];
  $status = [$status, $status[int(rand()*3)]] ;
  ok($rs->find($i)->update({ bitfield => $status}));
  foreach my $s (@{$status}) {
    is($rs->find($i)->$s, 1);
  }
}

ok($rs->update({ bitfield => 2 }));

foreach my $i (1..20) {
  is($rs->find($i)->status2, 1);
}

ok($rs->update_all({ bitfield => 'status2' }));

foreach my $i (1..20) {
  is($rs->find($i)->status2, 1);
}

ok($rs->update({ bitfield => ['status1', 'status3'] }));

foreach my $i (1..20) {
my $row = $rs->find($i);
  is($row->status1, 1);
  is($row->status3, 1);
  is_deeply($row->bitfield, ['status1', 'status3']);
  is($row->_bitfield, 5);
}










