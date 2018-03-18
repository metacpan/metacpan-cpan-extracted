package App::Controller::ApiBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::APIBase';
use Dwarf::DSL;
use App::Constant;
use Class::Method::Modifiers;

# バリデーションエラー時に直ちにエラーを送出するかどうか
sub _build_autoflush_validation_error { 1 }

sub init_plugins {
	load_plugins(
		'Error' => {
			LACK_OF_PARAM      => sub { shift->throw(1001, sprintf("missing mandatory parameters: %s", $_[0] || "")) },
			INVALID_PARAM      => sub { shift->throw(1002, sprintf("illegal parameter: %s", $_[0] || "")) },
			INVALID_SESSION    => sub { shift->throw(1003, sprintf("illegal session.")) },
			NEED_TO_LOGIN      => sub { shift->throw(1004, sprintf("You must login.")) },
			SNS_LIMIT_ERROR    => sub { shift->throw(2001, sprintf("SNS Limit Error: reset at %s", $_[0] || "")) },
			SNS_ERROR          => sub { shift->throw(2002, sprintf("SNS Error: %s", $_[0] || "SNS Error.")) },
			ERROR              => sub { shift->throw(9999, sprintf("%s", $_[0] || "Unknown Error.")) },
		},

		'CGI::SpeedyCGI' => {},
		'MouseX::Types::Common' => {},

		'CORS' => {
			origin      => c->base_url,
			credentials => 1,
			headers     => [qw/X-Requested-With Authorization Content-Type/],
			maxage      => 7200,
		},

		'JSON' => {
			pretty          => 1,
			convert_blessed => 1,
		},

		'XML::Simple' => {
			RootName      => 'test',
			NoAttr        => 1,
			KeyAttr       => [],
			SuppressEmpty => '' 
		},

		'HTTP::Session' => {
			session_key         => conf('/session/state/name'),
			session_table       => conf('/session/store/table'),
			session_expires     => 60 * 60 * 24 * 21,
			session_clean_thres => 1,
			param_name          => [qw/sessionId session_id/],
			cookie_path         => '/',
			cookie_domain       => undef,
			cookie_expires      => 60 * 60 * 24 * 21,
			cookie_secure       => conf('ssl') ? true : false,
			cookie_httponly     => 1,
		},
	);
}

sub will_dispatch {
}

sub did_dispatch {
}

after 'will_render' => sub {
	my ($self, $c, $data) = @_;
	return unless ref $data eq 'HASH';

	$data->{result} = 'success';

	if ($data->{error_code}) {
		$data->{result} = "fail";
	}
};

# 500 系のエラー
sub receive_server_error {
	my ($self, $c, $error) = @_;

	$error ||= 'Internal Server Error';
	print STDERR sprintf "[Server Error] %s\n", $error;

	load_plugins('Devel::StackTrace' => {});

	my $data = {
		error_code    => 500,
		error_message => $c->stacktrace($error),
	};

	return $data;
}

1;
