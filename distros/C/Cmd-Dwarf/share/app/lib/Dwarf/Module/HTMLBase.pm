package Dwarf::Module::HTMLBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::Util qw/merge_hash/;
use Dwarf::Validator;
use HTTP::Date;

use Dwarf::Accessor {
	ro => [qw/autoflush_validation_error/],
	rw => [qw/
		error_template error_vars
		server_error_template server_error_vars
	/],
};

# バリデーションエラー時に直ちにエラーを送出するかどうか
sub _build_autoflush_validation_error { 0 }

sub init {
	my ($self, $c) = @_;

	$c->error->autoflush(1) if $self->autoflush_validation_error;

	$c->add_trigger(BEFORE_RENDER => $self->can('will_render'));
	$c->add_trigger(AFTER_RENDER => $self->can('did_render'));
	$c->add_trigger(ERROR => $self->can('receive_error'));
	$c->add_trigger(SERVER_ERROR => $self->can('receive_server_error'));

	$self->type('text/html; charset=UTF-8');

	$self->header('Pragma' => 'no-cache');
	$self->header('Cache-Control' => 'no-cache');
	$self->header('Expires' => HTTP::Date::time2str(time - 24 * 60 * 60));
	$self->header('X-Content-Type-Options' => 'nosniff'); # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
	$self->header('X-Frame-Options' => 'DENY'); # http://blog.mozilla.com/security/2010/09/08/x-frame-options/

	$self->init_plugins($c);
	$self->call_before_trigger($c);
	$self->will_dispatch($c);
	$self->error->flush;
	$self->error->autoflush(1);
}

sub init_plugins  {
	my ($self, $c) = @_;

	$c->load_plugins(
		'Error' => {
			LACK_OF_PARAM   => sub { shift->throw(1001, @_) },
			INVALID_PARAM   => sub { shift->throw(1002, @_) },
			ERROR           => sub { shift->throw( 400, @_)->flush },
		},
		'Text::Xslate' => {},
	);

}

sub call_before_trigger {
	my ($self, $c) = @_;
	$c->call_trigger(BEFORE_DISPATCH => $c, $c->request);
}

sub will_dispatch {}

sub validate {
	my ($self, @rules) = @_;
	return unless @rules;
	my $validator = Dwarf::Validator->new($self->req)->check(@rules);
	if ($validator->has_error) {
		while (my ($param, $detail) = each %{ $validator->errors }) {
			$self->error->LACK_OF_PARAM($param, $detail) if $detail->{NOT_NULL};
			$self->error->INVALID_PARAM($param, $detail);
		}
	}
}

# レンダリング前の共通処理
sub will_render {
	my ($self, $c, $data) = @_;
}

# レンダリング後の共通処理
sub did_render {
	my ($self, $c, $data) = @_;
}

# 400 系のエラー
sub receive_error {
	my ($self, $c, $error) = @_;

	$self->{error_template} ||= '400.html';
	$self->{error_vars}     ||= $self->req->parameters->as_hashref;

	for my $message (@{ $error->messages }) {
		my $code   = $message->data->[0];
		my $param  = $message->data->[1];
		my $detail = $message->data->[2];

		$self->{error_vars}->{error}->{$param} = merge_hash(
			$self->{error_vars}->{error}->{$param},
			$detail
		);
	}

	return $c->render($self->error_template, $self->error_vars);
}

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

