# -*- perl -*-
use lib qw(t lib);
use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 4; 
    use_ok('Test::Pound');
}

my $pnd = new Test::Pound;
isa_ok($pnd, 'Config::Proxy::Impl::pound');

is(join(',', map { $_->arg(0) } $pnd->select ( name_ci => 'listenhttp' )),
   '"main","plain"',
   'simple select');

is(join(',', map { $_->arg(0) } $pnd->select ( name_ci => 'listenhttp',
					      arg => { n => 0, v => '"plain"' } )),
   '"plain"',
   'complex select');


__DATA__
ListenHTTP "main"
	Address 192.0.2.1
	Port    80
End
ListenHTTP "plain"
	Address 192.0.2.2
	Port    80
End



   
