package App::Controller::Api::Ping;
use Dwarf::Pragma;
use parent 'App::Controller::ApiBase';
use Dwarf::DSL;

sub get {
	return {
		hostname    => c->hostname,
		base_dir    => c->base_dir,
		config_name => c->config_name,
	};
}

1;

