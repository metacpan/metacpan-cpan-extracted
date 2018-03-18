package App::Controller::Api::Users;
use Dwarf::Pragma;
use parent 'App::Controller::ApiBase';
use Dwarf::DSL;
use Dwarf::Util qw/decode_utf8_recursively/;
use Class::Method::Modifiers;

after will_dispatch => sub {
	self->validate(
		id => [qw/NOT_BLANK UINT/],
	);

	self->validate_json_body(
		name => 'Str',
		tel  => 'JTel',
	);
};

sub post {
	return {
	};
}

1;
