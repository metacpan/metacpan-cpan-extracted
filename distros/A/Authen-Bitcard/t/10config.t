use Test::More tests => 8;
use strict;
use URI;
use_ok('Authen::Bitcard', 'load module');
ok(my $bc = Authen::Bitcard->new(), "new");
ok($bc->bitcard_url('http://test.bitcard.org/'), 'set bitcard_url');
ok($bc->token('a077fbb7942cbeb296dbac1de20020'), 'token');
ok(my $lurl = $bc->login_url(r => 'http://example.com/'), 'get login_url');

#my $u = URI->new('http://test.bitcard.org/login?bc_v=4&bc_r=http%3A%2F%2Fexample.com%2F&bc_t=a077fbb7942cbeb296dbac1de20020');
my $u = URI->new($lurl);

is_deeply({ $u->query_form },
	  +{ bc_v => 4,
	     bc_r => 'http://example.com/',
	     bc_t => 'a077fbb7942cbeb296dbac1de20020'
	   },
	  'login_url query parms'
	 );

ok($bc->info_required('email'), 'info_required');
is($bc->key_url,
   'http://test.bitcard.org/regkey.txt',
   'key_url'	
  );


