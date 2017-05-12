use strict;
use Test;
use Apache::Session::Flex;

BEGIN { plan tests => 4 }

require 't/testlib.pl';
my %config = read_config('t/CONFIG','Generate Serialize Servers');
ok(1);

my $session;
tie %{$session}, 'Apache::Session::Flex', undef, {
	Store     => 'Memcached',
	Lock      => 'Null',
	Generate  => $config{Generate},
	Serialize => $config{Serialize},
	Servers   => $config{Servers},
};

my $sid = $session->{_session_id};
ok( $session->{foo} = 'bar' );
untie %{$session};

tie %{$session}, 'Apache::Session::Flex', $sid, {
	Store     => 'Memcached',
	Lock      => 'Null',
	Generate  => $config{Generate},
	Serialize => $config{Serialize},
	Servers   => $config{Servers},
};

ok($session->{foo},'bar');

tied(%{$session})->delete;
ok(1);
