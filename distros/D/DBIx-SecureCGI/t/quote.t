use t::share;

plan tests => 6;

my $dbh = new_dbh {RaiseError=>1,PrintError=>0};

my $table_i = "DBIx_SecureCGI_test_a`b_$$";
my $table_i_q = "`DBIx_SecureCGI_test_a``b_$$`";
$dbh->do("CREATE TABLE $table_i_q (id int auto_increment primary key, i int)");
END { $dbh->do("DROP TABLE $table_i_q") }

my ($res, $wait);

is($dbh->quote_identifier($table_i), $table_i_q, 'manual quoting');
lives_ok { $dbh->do("INSERT INTO $table_i_q SET i=10")  } 'insert quoted';
dies_ok  { $dbh->do("INSERT INTO $table_i   SET i=15")  } 'insert non-quoted';

lives_ok { $dbh->Insert($table_i, {i=>20})              } 'Insert';
lives_ok { $res = [ $dbh->Select($table_i) ]            } 'Select';
$wait = [{id=>1,i=>10}, {id=>2,i=>20}];
is_deeply($res, $wait, 'Select return both records');

done_testing();
