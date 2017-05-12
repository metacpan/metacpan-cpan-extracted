BEGIN
{
	$| = 1;
	print "1..3\n";
}

eval
{
	require Apache;
};
if ($@) { print "not ok 1 [$@]\n"; }
else { print "ok 1\n"; }

eval
{
	require DBI;
};
if ($@) { print "not ok 2 [$@]\n"; }
else { print "ok 2\n"; }

eval
{
	require Apache::SearchEngineLog;
};
if ($@) { print "not ok 3 [$@]\n"; }
else { print "ok 3\n"; }
