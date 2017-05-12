# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################
use Test::More tests => 17;
#########################

unless (defined(do 't/dbia.config'))
{
	die $@ if $@;
	unless (defined(do 'dbia.config'))
	{
		die $@ if $@;
		die "Could not read dbia.config: $!\n";
	}
}
my %opt = load_all();

$conn = {
	user	=> $opt{'user'} || undef,
	password	=> $opt{'password'} || undef,
	};
if ($opt{'dsn'})
{
	$$conn{'dsn'}	= $opt{'dsn'};
} else {
	$$conn{'driver'}	= $opt{'driver'};
	$$conn{'dbname'}	= $opt{'db'};
	$$conn{'host'}  	= $opt{'host'};
	$$conn{'port'}  	= $opt{'port'};
}

eval {
	require DBIx::PDlib;
};
is($@, '', 'loading module');

eval {
	import DBIx::PDlib;
};
is($@, '', 'running import');

SKIP: {
	skip("Can't do database tests if you don't specify a driver",15)
		unless $$conn{'driver'};

	eval {
		$dbh = DBIx::PDlib->connect($conn);
		$dsn = $dbh->{'_dbh_args'}{'data_source'};
		if ($dbh->{'_dbh'}->{'Driver'}->{'Name'} eq 'mysql' or
		    $dbh->{'_dbh'}->{'Driver'}->{'Name'} eq 'mysqlPP')
		{
			$$conn{'dialect'} = 'MySQL';
		}
	};
	is(ref($dbh), 'DBIx::PDlib', 'connect dbname');

	ok( $dbh->connected(), "We are indeed connected.");

	eval {
		$dbh->disconnect if $dbh;
		my $dbi = DBI->connect($dsn,$$conn{'user'},$$conn{'password'});
		$dbh = DBIx::PDlib->connect($dbi);
	};
	is(ref($dbh), 'DBIx::PDlib', 'connect with dbi object');

	ok( $dbh->connected(), "We are indeed connected.");

	eval {
		$dbh->raw_query('create table foo (id int null,name char(30) not null,value char(30) null)');
		$dbh->raw_query('create table bar (id int null,foo_id int null,name char(30) not null)');
	};
	is($@,'','create');

	eval {
		$dbh->insert('foo',['id','name','value'],[1,'test','this']);
		$dbh->insert('foo',['id','name','value'],[2,'bar','baz']);
		$dbh->insert('foo',['id','name','value'],[3,'this','test']);
		$dbh->insert('foo',['id','name','value'],[4,'baz','bar']);
		$dbh->insert('bar',['id','foo_id','name'],[1,4,'heh']);
		$dbh->insert('bar',['id','foo_id','name'],[2,3,'heh']);
		$dbh->insert('bar',['id','foo_id','name'],[3,2,'heh']);
		$dbh->insert('bar',['id','foo_id','name'],[4,1,'baz']);
		$count1=4;
	};
	is($@,'','insert');

	eval {
		$dbh->update('foo',['name','value'],['blat','bonk'],'id = 2');
	};
	is($@,'','update');

	eval {
		($t_name,$t_value) = $dbh->select('name,value','foo',"id = '4'");
	};
	is( (!$@ && ($t_name eq 'baz') && ($t_value eq 'bar'))?1:0, 1, "select name=baz value=bar");

	eval {
		my $sth = $dbh->iterated_select('id','foo');
		while (@foo = $sth->fetchrow_array) { $count2++; }
	};
	is( (!$@ && ($count1 == $count2))?1:0, 1, "select ($count1==$count2)");

	eval {
		my $rv = $dbh->delete('foo','id = 4');
		my $sth = $dbh->iterated_select('id','foo');
		while (@foo = $sth->fetchrow_array) { $count3++; }
	};
	is( (!$@ && (($count1 - 1) == $count3))?1:0, 1, "delete");

	my $count4 = 0;
	eval {
		$dbh->delete('foo',"'1'");
		$dbh->delete('bar',"'1'");
		my $sth = $dbh->iterated_select('id','foo');
		while (@foo = $sth->fetchrow_array) { $count4++; }
		my $sth2 = $dbh->iterated_select('id','bar');
		while (@foo = $sth2->fetchrow_array) { $count4++; }
	};
	is( (!$@ and 0 == $count4)?1:0, 1, 'delete all');

	ok( $dbh->connected, 'verified connection');

	eval {
		$dbh->raw_query('drop table foo');
		$dbh->raw_query('drop table bar');
	};
	is($@,'','drop');

	eval {
		$dbh->disconnect();
	};
	ok(! $@, 'disconnect');

	ok(! $dbh->connected, 'verified disconnect');

};
