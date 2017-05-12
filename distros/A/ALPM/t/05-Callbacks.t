use Test::More;
use ALPM::Conf 't/test.conf';

ok !defined $alpm->get_logcb;
$cb = sub { print "LOG: @_" };
die 'internal error' unless(ref($cb) eq 'CODE');
$alpm->set_logcb($cb);

$tmp = $alpm->get_logcb($cb);
is ref($tmp), 'CODE';
ok $tmp eq $cb;

$alpm->set_logcb(undef);
ok !defined $alpm->get_logcb;

done_testing;
