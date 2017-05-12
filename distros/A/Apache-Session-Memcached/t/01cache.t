use strict;
use Test;
use Apache::Session::Memcached;

BEGIN { plan tests => 4 }

require 't/testlib.pl';
my %config = read_config('t/CONFIG','Generate Serialize Servers');
ok(1);

my $session;
tie %{$session}, 'Apache::Session::Memcached', undef, {
	Servers => $config{Servers},
};

my $sid = $session->{_session_id};
ok( $session->{foo} = 'bar' );
untie %{$session};

tie %{$session}, 'Apache::Session::Memcached', $sid, {
  	Servers => [ split(/\s+/,$config{Servers}) ],
};

ok($session->{foo},'bar');

tied(%{$session})->delete;
ok(1);
