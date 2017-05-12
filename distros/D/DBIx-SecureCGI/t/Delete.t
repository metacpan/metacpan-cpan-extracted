use t::share;

# plan tests => ;

my $cv;
my $dbh = new_adbh;
my $table = new_table "id $PK, i INT, s VARCHAR(255)";

sub fill_table {
    $dbh->do('TRUNCATE TABLE '.$dbh->quote_identifier($table));
    $dbh->Insert($table, {i=>1,s=>'one'});
    $dbh->Insert($table, {i=>2,s=>'two'});
    $dbh->Insert($table, {i=>3,s=>'three'});
    $dbh->Insert($table, {i=>30,s=>'three'});
    $dbh->Insert($table, {i=>300,s=>'three'});
    $dbh->Insert($table, {i=>4,s=>'four'});
    $dbh->Insert($table, {i=>5,s=>'five'});
}

# one table, sync
ok !$dbh->Delete("no_such_$table"), 'one table, sync';
like $dbh->errstr, qr/doesn't exist/;
ok !$dbh->Delete($table);
like $dbh->errstr, qr/empty WHERE/;
ok !$dbh->Delete($table, {__force=>0});
like $dbh->errstr, qr/empty WHERE/;
is $dbh->Delete($table, {__force=>1}), '0E0';
fill_table();
is $dbh->Delete($table, {__force=>1}), '7';
is $dbh->Count($table), 0;
fill_table();
is $dbh->Delete($table, {s=>'three',__limit=>2}), '2';
is $dbh->Delete($table, {s=>'three',__limit=>2}), '1';
is $dbh->Delete($table, {s=>'three',__limit=>2}), '0E0';
is $dbh->Count($table), 4;
ok !$dbh->Delete($table, {__limit=>[2,3]});
like $dbh->errstr, qr/empty WHERE/;
$dbh->do('TRUNCATE TABLE '.$dbh->quote_identifier($table));

# one table, async
$dbh->Delete("no_such_$table", {}, $cv=AE::cv);
ok !$cv->recv, 'one table, async';
like $dbh->errstr, qr/doesn't exist/;
$dbh->Delete($table, {}, $cv=AE::cv);
ok !$cv->recv;
like $dbh->errstr, qr/empty WHERE/;
$dbh->Delete($table, {__force=>0}, $cv=AE::cv);
ok !$cv->recv;
like $dbh->errstr, qr/empty WHERE/;
$dbh->Delete($table, {__force=>1}, $cv=AE::cv);
is $cv->recv, '0E0';
fill_table();
$dbh->Delete($table, {__force=>1}, $cv=AE::cv);
is $cv->recv, '7';
$dbh->Count($table, {}, $cv=AE::cv);
is $cv->recv, 0;
fill_table();
$dbh->Delete($table, {s=>'three',__limit=>2}, $cv=AE::cv);
is $cv->recv, '2';
$dbh->Delete($table, {s=>'three',__limit=>2}, $cv=AE::cv);
is $cv->recv, '1';
$dbh->Delete($table, {s=>'three',__limit=>2}, $cv=AE::cv);
is $cv->recv, '0E0';
$dbh->Count($table, {}, $cv=AE::cv);
is $cv->recv, 4;
$dbh->Delete($table, {__limit=>[2,3]}, $cv=AE::cv);
ok !$cv->recv;
like $dbh->errstr, qr/empty WHERE/;
$dbh->do('TRUNCATE TABLE '.$dbh->quote_identifier($table));

my $table1 = new_table "id_t1 $PK, i INT";
my $table2 = new_table "id_t2 $PK, id_t1 INT, s VARCHAR(255)";
my $table3 = new_table "id_t3 $PK, id_t1 INT, d DATE";
my $table4 = new_table "id_t4 $PK, id_t1 INT, id_t2 INT, t TEXT";
my $table5 = new_table "id_t5 $PK, n INT";

sub fill_tables {
    $dbh->do('TRUNCATE TABLE '.$dbh->quote_identifier($_))
        for $table1,$table2,$table3,$table4,$table5;
    $dbh->Insert($table1, {i=>11});
    $dbh->Insert($table1, {i=>12});
    $dbh->Insert($table2, {id_t1=>1, s=>'one'});
    $dbh->Insert($table2, {id_t1=>1, s=>'first'});
    $dbh->Insert($table2, {id_t1=>2, s=>'two'});
    $dbh->Insert($table2, {id_t1=>2, s=>'second'});
    $dbh->Insert($table3, {id_t1=>1, d__set_date=>'now'});
    $dbh->Insert($table3, {id_t1=>2, d__set_date=>'now'});
    $dbh->Insert($table4, {id_t1=>1, id_t2=>1, t=>'ONE'});
    $dbh->Insert($table4, {id_t1=>2, id_t2=>3, t=>'TWO'});
    $dbh->Insert($table5, {n=>100});
}

# multi table, sync
fill_tables();
is $dbh->Count($table1), 2;
is $dbh->Count($table2), 4;
is $dbh->Delete([$table1,$table2], {id_t1=>1}), 2, 'multi table, sync';
is $dbh->Count($table1), 1;
is $dbh->Count($table2), 2;
is $dbh->Delete([$table2,$table1], {id_t1=>2}), 1;
fill_tables();
ok !$dbh->Delete([$table1,"no_such_$table",$table2], {id_t1=>1});
like $dbh->errstr, qr/doesn't exist/;
is $dbh->Count($table1), 1;
is $dbh->Count($table2), 4;
fill_tables();
ok !$dbh->Delete([$table1,$table,$table2], {id_t1=>1});
like $dbh->errstr, qr/empty WHERE/;
is $dbh->Count($table1), 1;
is $dbh->Count($table2), 4;
fill_table();
fill_tables();
is $dbh->Count($table), 7;
is $dbh->Count($table1), 2;
is $dbh->Count($table2), 4;
ok $dbh->Delete([$table1,$table,$table2], {id_t1=>1,__force=>1});
is $dbh->Count($table), 0;
is $dbh->Count($table1), 1;
is $dbh->Count($table2), 2;

# multi table, async
fill_tables();
is $dbh->Count($table1), 2;
is $dbh->Count($table2), 4;
$dbh->Delete([$table1,$table2], {id_t1=>1}, $cv=AE::cv);
is $cv->recv, 2, 'multi table, async';
is $dbh->Count($table1), 1;
is $dbh->Count($table2), 2;
$dbh->Delete([$table2,$table1], {id_t1=>2}, $cv=AE::cv);
is $cv->recv, 1;
fill_tables();
$dbh->Delete([$table1,"no_such_$table",$table2], {id_t1=>1}, $cv=AE::cv);
ok !$cv->recv;
like $dbh->errstr, qr/doesn't exist/;
is $dbh->Count($table1), 1;
is $dbh->Count($table2), 4;
fill_tables();
$dbh->Delete([$table1,$table,$table2], {id_t1=>1}, $cv=AE::cv);
ok !$cv->recv;
like $dbh->errstr, qr/empty WHERE/;
is $dbh->Count($table1), 1;
is $dbh->Count($table2), 4;
fill_table();
fill_tables();
is $dbh->Count($table), 7;
is $dbh->Count($table1), 2;
is $dbh->Count($table2), 4;
$dbh->Delete([$table1,$table,$table2], {id_t1=>1,__force=>1}, $cv=AE::cv);
ok $cv->recv;
is $dbh->Count($table), 0;
is $dbh->Count($table1), 1;
is $dbh->Count($table2), 2;

# all tables, sync
fill_table();
fill_tables();
is $dbh->Count($table), 7;
is $dbh->Count($table1), 2;
is $dbh->Count($table2), 4;
is $dbh->Count($table3), 2;
is $dbh->Count($table4), 2;
is $dbh->Count($table5), 1;
is $dbh->Delete(undef, {id_t1=>1}), 1, 'all tables, sync';
is $dbh->Count($table), 7;
is $dbh->Count($table1), 1;
is $dbh->Count($table2), 2;
is $dbh->Count($table3), 1;
is $dbh->Count($table4), 1;
is $dbh->Count($table5), 1;

# all tables, async
fill_table();
fill_tables();
is $dbh->Count($table), 7;
is $dbh->Count($table1), 2;
is $dbh->Count($table2), 4;
is $dbh->Count($table3), 2;
is $dbh->Count($table4), 2;
is $dbh->Count($table5), 1;
$dbh->Delete(undef, {id_t1=>1}, $cv=AE::cv);
is $cv->recv, 1, 'all tables, async';
is $dbh->Count($table), 7;
is $dbh->Count($table1), 1;
is $dbh->Count($table2), 2;
is $dbh->Count($table3), 1;
is $dbh->Count($table4), 1;
is $dbh->Count($table5), 1;

done_testing;
