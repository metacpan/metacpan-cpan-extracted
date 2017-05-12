#!/usr/bin/perl
##
# Initialize ALPM then set and check a few options.
# Checks add/remove on what we can.
# Then create the test repositories.

use Test::More;

BEGIN { use_ok('ALPM') };

## I could not hack this into the Makefile so we initialize
## test repositories here so the modules required are
## only needed when running the tests.

if(system 'perl' => 't/preptests.pl'){
	die 'failed to initialize our test root/packages/repos';
}

$ENV{'LANGUAGE'} = 'en_US';

$r = 't/root';
$alpm = ALPM->new($r, "$r/db");
ok $alpm;

ok $alpm->version; # just checks it works
@caps = $alpm->caps;

%opts = (
	'arch' => 'i686',
	'logfile' => "$r/log",
	'gpgdir' => "$r/gnupg",
	'cachedirs' => [ "$r/cache/" ], # needs trailing slash
	'noupgrades' => [ 'foo' ],
	'noextracts' => [ 'bar' ],
	'ignorepkgs' => [ 'baz' ],
	'ignoregroups' => [ 'core' ],
	'usesyslog' => 0,
	'deltaratio' => 0.5,
	'checkspace' => 1,
);

sub meth
{
	my $name = shift;
	my $m = *{"ALPM::$name"}{CODE} or die "missing $name method";
	my @ret = eval { $m->($alpm, @_) };
	if($@){ die "method call to $name failed: $@" }
	return (wantarray ? @ret : $ret[0]);
}

for $k (sort keys %opts){
	$v = $opts{$k};
	@v = (ref $v ? @$v : $v);
	ok meth("set_$k", @v), "set_$k successful";

	@x = meth("get_$k");
	is $#x, $#v, "get_$k returns same size list as set_$k";
	for $i (0 .. $#v){
		is $x[$i], $v[$i], "get_$k has same value as set_$k args";
	}

	next unless($k =~ s/s$//);
	is meth("remove_$k", $v[0]), 1, "remove_$k reported success";
	@w = meth("get_${k}s");
	ok @w == (@v - 1), "$v[0] removed from ${k}s";
}

# TODO: Test SigLevels more in a later test.
is_deeply $alpm->get_defsiglvl, { 'pkg' => 'never', 'db' => 'never' };

if(grep { /signatures/ } @caps){
	$siglvl = { 'pkg' => 'optional', 'db' => 'required' };
	ok $alpm->set_defsiglvl($siglvl);
	is_deeply $alpm->get_defsiglvl, $siglvl;

	$siglvl = { 'pkg' => 'never', 'db' => 'optional trustall' };
	ok $alpm->set_defsiglvl($siglvl);
	is_deeply $alpm->get_defsiglvl, $siglvl;
}else{
	$siglvl = { 'pkg' => 'never', 'db' => 'required' };
	eval { $alpm->set_defsiglvl($siglvl); };
	if($@ =~ /^ALPM Error: wrong or NULL argument passed/){
		pass q{can set siglevel to "never" without GPGME};
	}else{
		fail 'should not be able to set complicated siglevel without GPGME';
	}
}

ok not eval { $alpm->set_defsiglvl('default') };

done_testing;
