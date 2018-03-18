use Dwarf::Pragma;
use Dwarf;
use Dwarf::Util qw/load_class/;
use Test::More 0.88;

subtest "config" => sub {
	my $c = Dwarf->new;
	is ref $c->config, 'Dwarf::Config', 'has config';

	$c->conf(test => 1);
	is $c->conf('test'), 1, 'getter/setter works fine';
};

subtest "error" => sub {
	my $c = Dwarf->new;
	is ref $c->error, 'Dwarf::Error', 'has error';
}; 

subtest "request" => sub {
	my $c = Dwarf->new;
	is ref $c->req, 'Dwarf::Request', 'has request';
}; 

subtest "response" => sub {
	my $c = Dwarf->new;
	is ref $c->res, 'Dwarf::Response', 'has response';
}; 

subtest "router" => sub {
	my $c = Dwarf->new;
	is ref $c->router, 'Router::Simple', 'has router';

	my $p = $c->router->match({
		PATH_INFO => '/api/ping',
	});
	#warn $c->dump($p);
	is $p->{controller}, 'Api', 'find controller';
	is $p->{splat}->[0], 'ping', 'find action';

	$p = $c->router->match({
		PATH_INFO => '/hoge/ping',
	});
	#warn $c->dump($p);
	is $p->{controller}, 'Web', 'does not find controller';
	is $p->{splat}->[0], '/hoge/ping', 'does not find action';
};

subtest "is_production" => sub {
	my $c = Dwarf->new;
	is $c->is_production, 1, 'works fine';
};

subtest "is_cli" => sub {
	my $c = Dwarf->new(env => {
		SERVER_SOFTWARE => 'Plack::Handler::CLI',
	});
	is $c->is_cli, 1, 'works fine';
};

subtest "dispatch" => sub {
	my $c = Dwarf->new(env => {
		REQUEST_METHOD => 'GET',
		PATH_INFO      => '/api/ping',
	});
	$c->{namespace} = 'Dwarf::Test';
	$c->{request_handler_prefix} = $c->namespace . '::Controller';
	$c->dispatch;
	my $res = $c->finalize;
	is $res->[0], 200, 'works fine';
};

subtest "finish" => sub {
	my $c = Dwarf->new;
	eval { $c->finish };
	is ref $@, "Dwarf::Message", 'works fine';
};

subtest "redirect" => sub {
	my $c = Dwarf->new;
	my $to = 'http://apple.com/jp/';
	eval { $c->redirect($to) };
	my $res = $c->finalize;
	is_deeply($res, [302, [
		'Location'     => $to,
		'Content-Type' => 'text/plain',
	], []], 'works fine');
};

subtest "unauthorized" => sub {
	my $c = Dwarf->new;
	eval { $c->unauthorized };
	my $res = $c->finalize;
	is $res->[0], 401, 'works fine';
};

subtest "not_found" => sub {
	my $c = Dwarf->new;
	eval { $c->not_found };
	my $res = $c->finalize;
	is $res->[0], 404, 'works fine';
};

subtest "handle_error" => sub {
	my $c = Dwarf->new;
	eval { $c->handle_error('hoge') };
	my $res = $c->finalize;
	is $res->[0], 400, 'works fine';
};

subtest "handle_server_error" => sub {
	my $c = Dwarf->new;
	eval { $c->handle_server_error('hoge') };
	my $res = $c->finalize;
	is $res->[0], 500, 'works fine';
};

subtest "find_class" => sub {
	my $c = Dwarf->new;
	my ($class, $ext) = $c->find_class('/api/ping.json');
	is_deeply([ $class, $ext ], [ 'Dwarf::Controller::Api::Ping', 'json' ], 'works fine');
};

subtest "find_method" => sub {
	my $c = Dwarf->new(env => {
		REQUEST_METHOD => 'GET',
	});

	my $controller = "Dwarf::Test::Controller::Api::Ping";
	Dwarf::Util::load_class($controller);
	$c->{handler} = $controller->new(context => $c);

	my $method = $c->find_method;
	ok ref $method eq 'CODE', 'works fine';
};

subtest "model" => sub {
	my $c = Dwarf->new;
	$c->{namespace} = 'Dwarf::Test';
	my $m = $c->model('Hoge');
	is $c->models->{'Dwarf::Test::Model::Hoge'}, $m, 'works fine';
};

subtest "proctitle" => sub {
	my $c = Dwarf->new;
	my $title = 'dwarf test';
	$c->proctitle($title);
	SKIP: {
		skip('linux is not supported', 1) if $^O eq 'linux';
		is $0, $title, 'proctitle works fine';
	}
};

subtest "load_plugin" => sub {
	my $c = Dwarf->new;
	$c->load_plugin('MultiConfig');
	ok $c->can('hostname'), 'works fine';
};

done_testing();
