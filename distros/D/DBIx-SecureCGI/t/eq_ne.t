use lib 't';
use share;

plan tests => 24;

my $dbh = new_dbh;
my $table_i = new_table 'id int auto_increment primary key, i int';
$dbh->do("INSERT INTO $table_i SET i=?", undef, $_) for undef,0,1,2;

my @test_i = (
    "i=>undef"		    => [{id=>1,i=>undef}],
    "i=>0"		    => [{id=>2,i=>0}],
    "i=>2"		    => [{id=>4,i=>2}],
    "i=>3"		    => [],
    "i__eq=>[]"		    => [],
    "i__eq=>[undef]"	    => [{id=>1,i=>undef}],
    "i__eq=>[undef,undef]"  => [{id=>1,i=>undef}],
    "i__eq=>[0]"	    => [{id=>2,i=>0}],
    "i__eq=>[1,2]"	    => [{id=>3,i=>1},{id=>4,i=>2}],
    "i__eq=>[undef,0,1]"    => [{id=>1,i=>undef},{id=>2,i=>0},{id=>3,i=>1}],
    "i__eq=>[0,undef,1]"    => [{id=>1,i=>undef},{id=>2,i=>0},{id=>3,i=>1}],
    "i__eq=>[undef,1,undef,undef,2,undef,2,1,2]"
			    => [{id=>1,i=>undef},{id=>3,i=>1},{id=>4,i=>2}],
    );

while (@test_i) {
    my ($test, $wait) = (shift @test_i, shift @test_i);
    my @res = $dbh->Select($table_i, {eval($test),-order=>["id"]});
    is_deeply(\@res, $wait, $test);
}

my $table_s = new_table 'id int auto_increment primary key, s varchar(255)';
$dbh->do("INSERT INTO $table_s SET s=?", undef, $_) for undef,q{},0,'test';

my @test_s = (
    "s=>undef"		    => [{id=>1,s=>undef}],
    "s=>''"		    => [{id=>2,s=>""}],
    "s=>'test'"		    => [{id=>4,s=>"test"}],
    "s=>'oops'"		    => [],
    "s__eq=>[]"		    => [],
    "s__eq=>[undef]"	    => [{id=>1,s=>undef}],
    "s__eq=>[undef,undef]"  => [{id=>1,s=>undef}],
    "s__eq=>['']"	    => [{id=>2,s=>""}],
    "s__eq=>['0','test']"   => [{id=>3,s=>"0"},{id=>4,s=>"test"}],
    "s__eq=>[undef,'','0']" => [{id=>1,s=>undef},{id=>2,s=>""},{id=>3,s=>"0"}],
    "s__eq=>['',undef,'0']" => [{id=>1,s=>undef},{id=>2,s=>""},{id=>3,s=>"0"}],
    "s__eq=>[undef,'0',undef,undef,'test',undef,'test','0','test']"
			    => [{id=>1,s=>undef},{id=>3,s=>"0"},{id=>4,s=>"test"}],
    );

while (@test_s) {
    my ($test, $wait) = (shift @test_s, shift @test_s);
    my @res = $dbh->Select($table_s, {eval($test),-order=>["id"]});
    is_deeply(\@res, $wait, $test);
}

done_testing();
