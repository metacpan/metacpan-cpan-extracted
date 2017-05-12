use Test::More;
use ALPM::Conf 't/test.conf';

sub pkgpath
{
	my($dbname, $pkgname) = @_;
	$db = $alpm->db($dbname);
	$db->update or die $alpm->err;
	my($url) = $db->get_servers;
	$pkg = $db->find($pkgname) or die "$dbname/$pkgname package is missing";
	$url .= q{/} . $pkg->filename;
	print "$url\n";
	if(($url =~ s{^file://}{}) != 1){
		die 'package files are not locally hosted as expected';
	}
	return $url;
}

$msg = 'load the simpletest/foo package file';
$pkg = $alpm->load_pkgfile(pkgpath('simpletest', 'foo'), 1, 'default');
if($pkg){
	pass $msg;
}else{
	fail $msg;
	die $alpm->strerror;
}

my @methnames = qw{ requiredby name version desc
                    url builddate installdate packager
                    arch arch size isize reason
                    licenses groups depends optdepends
                    conflicts provides deltas replaces
                    files backup };

for my $mname (@methnames) {
    my $method_ref = $ALPM::Package::{$mname};
    ok $method_ref, "$mname is a package method";
    my $result = $method_ref->($pkg);
    ok defined $result, "$mname has a defined value";
}

ok defined $pkg->changelog;

done_testing;
