use Test::More;

use ALPM::Conf 't/test.conf';
ok $alpm;

sub checkpkgs
{
	my $db = shift;
	my $dbname = $db->name;
	my %set = map { ($_ => 1) } @_;
	for my $p ($db->pkgs){
		my $n = $p->name;
		unless(exists $set{$n}){
			fail "unexpected $n package exists in $dbname";
			return;
		}
		delete $set{$n};
	}
	if(keys %set){
		fail "missing packages in $dbname: " . join q{ }, keys %set;
	}else{
		pass "all expected packages exist in $dbname";
	}
}

sub checkdb
{
	my $dbname = shift;
	my $db = $alpm->db($dbname);
	is $db->name, $dbname, 'dbname matches db() arg';
	checkpkgs($db, @_);
}

$db = $alpm->localdb;
is $db->name, 'local';

## Make sure DBs are synced.
$_->update or die $alpm->strerror for($alpm->syncdbs);

checkdb('simpletest', qw/foo bar/);
checkdb('upgradetest', qw/foo replacebaz/);

## Check that register siglevel defaults to 'default' when not provided.
$db = $alpm->register('empty') or die 'register failed';

## Due to libalpm trickery, if the db's siglevel is set to default, then the siglevel
## that is retrieved is a copy of the handle's default siglevel.
$siglvl = $alpm->get_defsiglvl;
is_deeply $db->siglvl, $siglvl;

done_testing;
