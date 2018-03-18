package Dwarf::Module::APIBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::Validator;
use Dwarf::Validator::Constraint;
use Dwarf::Util qw/safe_decode_json encode_utf8/;
use Carp qw/croak/;
use HTTP::Date;

use Dwarf::Accessor {
	ro => [qw/autoflush_validation_error/],
};

# バリデーションエラー時に直ちにエラーを送出するかどうか
sub _build_autoflush_validation_error { 1 }


sub init {
	my ($self, $c) = @_;

	$c->error->autoflush(1) if $self->autoflush_validation_error;

	$c->add_trigger(BEFORE_RENDER => $self->can('will_render'));
	$c->add_trigger(AFTER_RENDER => $self->can('did_render'));
	$c->add_trigger(ERROR => $self->can('receive_error'));
	$c->add_trigger(SERVER_ERROR => $self->can('receive_server_error'));
	
	$self->header('Pragma' => 'no-cache');
	$self->header('Cache-Control' => 'no-cache');
	$self->header('Expires' => HTTP::Date::time2str(time - 24 * 60 * 60));
	$self->header('X-Content-Type-Options' => 'nosniff'); # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
	$self->header('X-Frame-Options' => 'DENY'); # http://blog.mozilla.com/security/2010/09/08/x-frame-options/
	
	$self->init_plugins($c);

	$self->type('application/json; charset=UTF-8');

	# defense from JSON hijacking
	my $user_agent = $c->req->user_agent || '';
	my $request_method = $c->req->method || 'GET';
	if ((!$c->req->header('X-Requested-With')) && $user_agent =~ /android/i && defined $c->req->header('Cookie') && $request_method eq 'GET') {
		$c->{response} = $c->req->new_response;
		$c->res->status(403);
		$c->res->content_type('text/html; charset=utf-8');
		$c->finish("Your request may be JSON hijacking.\nIf you are not an attacker, please add 'X-Requested-With' header to each request.");
	}

	if (defined $c->ext and $c->ext eq 'xml' and $c->can('encode_xml')) {
		$self->type('application/xml; charset=UTF-8');
	}

	$self->will_dispatch($c);
	$self->error->flush;
	$self->error->autoflush(1);
}

sub init_plugins  {
	my ($self, $c) = @_;

	$c->load_plugins(
		'Error'       => {
			LACK_OF_PARAM   => sub { shift->throw(1001, sprintf("missing mandatory parameters: %s", $_[0] || "")) },
			INVALID_PARAM   => sub { shift->throw(1002, sprintf("illegal parameter: %s", $_[0] || "")) },
			NEED_TO_LOGIN   => sub { shift->throw(1003, sprintf("You must login.")) },
			SNS_LIMIT_ERROR => sub { shift->throw(2001, sprintf("SNS Limit Error: reset at %s", $_[0] || "")) },
			SNS_ERROR       => sub { shift->throw(2002, sprintf("SNS Error: %s", $_[0] || "SNS Error.")) },
			ERROR           => sub { shift->throw(400,  sprintf("%s", $_[0] || "Unknown Error.")) },
		},
		'JSON'        => { pretty => 1 },
		'XML::Simple' => {
			NoAttr        => 1,
			KeyAttr       => [],
			SuppressEmpty => '' 
		},
	);
}

sub will_dispatch {}
sub did_dispatch {}

sub validate {
	my ($self, @rules) = @_;
	return unless @rules;

	my $validator = Dwarf::Validator->new($self->c->req)->check(@rules);
	if ($validator->has_error) {
		while (my ($param, $detail) = each %{ $validator->errors }) {
			$self->c->error->LACK_OF_PARAM($param) if $detail->{NOT_NULL} || $detail->{NOT_BLANK};
			$self->c->error->LACK_OF_PARAM($param) if $detail->{FILE_NOT_NULL};
			$self->c->error->INVALID_PARAM($param);
		}
	}
}

sub validate_json_body {
	my ($self, @rules) = @_;
	my $json = $self->c->req->content;

	$json = eval { safe_decode_json(encode_utf8 $json) };
	if ($@) {
		$self->c->error->ERROR('JSON decode error: ' . $@);
	}

	$json = [ $json ] unless ref $json eq 'ARRAY';

	eval { $self->args({ @rules }, $self, $_) for @$json };
	if ($@) {
		$self->c->error->ERROR($@);
	}
}

sub validate_response {
	my ($self, @rules) = @_;
	return if $self->c->is_production;

	my $res = $self->c->response->body;

	eval { $self->args({ @rules }, $self, $res) };
	if ($@) {
		$self->c->error->ERROR($@);
	}
}

# レンダリング前の共通処理
sub will_render {
	my ($self, $c, $data) = @_;
	$self->response_http_status($data);
}

# レンダリング後の共通処理
sub did_render {
	my ($self, $c, $data) = @_;
}

# 400 系のエラー
sub receive_error {
	my ($self, $c, $error) = @_;
	my (@codes, @messages);

	for my $m (@{ $error->messages }) {
		print STDERR sprintf "[API Error] code = %s, message = %s\n", $m->data->[0], $m->data->[1];
		push @codes, $m->data->[0];
		push @messages, $m->data->[1];
	}

	my $data = {
		error_code    => @codes == 1 ? $codes[0] : \@codes,
		error_message => @messages == 1 ? $messages[0] : \@messages,
	};

	return $data;
}

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

# HTTP ステータスの調整
sub response_http_status {
	my ($self, $data) = @_;
	$data ||= {};
	return unless ref $data eq 'HASH';

	my $status = 200;
	if ($data->{error_code}) {
		$status = $data->{error_code} == 500 ? 500 : 400;
	}

	if (defined $self->param('response_http_status')) {
		$self->status(scalar $self->param('response_http_status'));
		$data->{http_status} ||= $status;
		$status = 200;
	}

	$self->res->status($status);
}

1;
