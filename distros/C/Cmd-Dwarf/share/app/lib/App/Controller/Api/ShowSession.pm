package App::Controller::Api::ShowSession;
use Dwarf::Pragma;
use parent 'App::Controller::ApiBase';
use Dwarf::DSL;
use Dwarf::Util qw/decode_utf8_recursively/;
use App::Type;
use Class::Method::Modifiers;

after will_dispatch => sub {
};

after did_dispatch => sub {
	self->validate_response(
		id      => 'Str',
		session => 'HashRef',
		cookie  => 'HashRef',
	);
};

sub get {
	# 本番では動かないように
	not_found if is_production;

	return {
		id       => session->session_id,
		session  => decode_utf8_recursively(session->as_hashref),
		cookie   => decode_utf8_recursively(req->cookies)
	};
}

1;
