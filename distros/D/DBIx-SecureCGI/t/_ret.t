use lib 't';
use share;

plan tests => 14;

my $cv = AnyEvent->condvar;
my $dbh = new_adbh;
my $table = new_table "id $PK, i INT";

*_ret = \&DBIx::SecureCGI::_ret;
*_ret1 = \&DBIx::SecureCGI::_ret1;
*_retdo = \&DBIx::SecureCGI::_retdo;

is_deeply [_ret(undef)], [];
is_deeply [_ret(undef,undef)], [undef];
is_deeply [_ret(undef,1,q{})], [1,q{}];
_ret(sub { is_deeply \@_, [] });
_ret(sub { is_deeply \@_, [undef] }, undef);
_ret(sub { is_deeply \@_, [1,q{}] }, 1,q{});

is_deeply [_ret1(undef, undef,  $dbh)], [undef];
is_deeply [_ret1(undef, 1,      $dbh)], [1];
is_deeply [_ret1(undef, q{},    $dbh)], [q{}];
_ret1(sub { is_deeply \@_, [undef,  $dbh] },  undef,    $dbh);
_ret1(sub { is_deeply \@_, [1,      $dbh] },  1,        $dbh);
_ret1(sub { is_deeply \@_, [q{},    $dbh] },  q{},      $dbh);

is_deeply [_retdo($dbh,'SELECT 1')], [1];
_retdo($dbh,'SELECT 1',sub { is_deeply \@_, [1,$dbh]; $cv->send });
$cv->recv;

done_testing();
