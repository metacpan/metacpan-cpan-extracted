use lib '.';
use t::Helper;

my $tt = t::Helper->tt;
ok $tt->can("command_$_"), "tt $_" for qw(export log start stop status register);

eval { $tt->_time('13T29') };
like $@, qr{Invalid time: 13T29}, 'invalid time';
test_time('2019-01-03T23:02:01', '2019-01-03T23:02:01');
test_time('2019-1-03T23:2:01',   '2019-01-03T23:02:01');
test_time('3T23',                '03T23:00:00');
test_time('9-3T23',              '09-03T23:00:00');
test_time('6:5',                 'T06:05:00');
test_time('09:04:01',            'T09:04:01');

done_testing;

sub test_time {
  my ($str, $exp) = @_;
  my $tp = $tt->_time($str);
  like $tp->datetime, qr{$exp}, "$exp = $tp";
}
