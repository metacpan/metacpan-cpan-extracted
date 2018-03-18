package App::Controller::Api::Ping;
use Dwarf::Pragma;
use parent 'App::Controller::ApiBase';
use Dwarf::DSL;
use App::Type;
use Class::Method::Modifiers;

after will_dispatch => sub {
};

after did_dispatch => sub {
	self->validate_response(
		hostname    => 'Str',
		base_dir    => 'Str',
		config_name => 'Str',
	);
};

sub get {
	return {
		hostname    => c->hostname,
		base_dir    => c->base_dir,
		config_name => c->config_name,
	};
}

1;

