use Test::More tests => 5;

BEGIN {
	use_ok( 'Catalyst::Model::REST' );
}

diag( "Testing Catalyst::Model::REST $Catalyst::Model::REST::VERSION, Perl $], $^X" );
ok(my $rest = Catalyst::Model::REST->new(type => 'application/json', server => 'http://localhost:123456'), 'Create REST instance');
isa_ok($rest, 'Catalyst::Model::REST', 'REST');
isa_ok($rest->_serializer, 'Role::REST::Client::Serializer', 'JSON serializer');
ok($rest->get('/xyzzy'), 'get OK');