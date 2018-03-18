package App::Controller::WebBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::HTMLBase';
use Dwarf::DSL;
use App::Constant;

# バリデーションエラー時に直ちにエラーを送出するかどうか
sub _build_autoflush_validation_error { 0 }

sub init_plugins {
	load_plugins(
		'Error' => {
			LACK_OF_PARAM   => sub { shift->throw(1001, @_) },
			INVALID_PARAM   => sub { shift->throw(1002, @_) },
			ERROR           => sub { shift->throw( 400, @_)->flush },
		},
		'CGI::SpeedyCGI' => {},
		'Text::Xslate' => {},
		'HTTP::Session' => {
			session_key         => conf('/session/state/name'),
			session_table       => conf('/session/store/table'),
			session_expires     => 60 * 60 * 24 * 21,
			session_clean_thres => 1,
			param_name          => 'session_id',
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

# テンプレートに渡す共通の値を定義することなどに使う
# 例）ヘッダなど
# sub will_render {
#	my ($self, $c, $data) = @_;
# }

# 500 系のエラー
sub receive_server_error {
	my ($self, $c, $error) = @_;
	print STDERR sprintf "[Server Error] %s\n", $error;
	load_plugins('Devel::StackTrace' => {});
	$self->{server_error_template}    ||= '500.html';
	$self->{server_error_vars} ||= { error => $c->stacktrace($error) };
	return $c->render($self->server_error_template, $self->server_error_vars);
}

1;

