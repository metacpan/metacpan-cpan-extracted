package Dwarf::Module::CLIBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::Validator;

use Dwarf::Accessor {
	ro => [qw/autoflush_validation_error/],
};

# バリデーションエラー時に直ちにエラーを送出するかどうか
sub _build_autoflush_validation_error { 1 }

sub init {
	my ($self, $c) = @_;
	$c->not_found if $c->is_production and not $c->is_cli;

	$c->error->autoflush(1) if $self->autoflush_validation_error;

	$c->load_plugins(
		'Error' => {
			LACK_OF_PARAM   => sub { shift->throw(1001, sprintf("missing mandatory parameters: %s", $_[0] || "")) },
			INVALID_PARAM   => sub { shift->throw(1002, sprintf("illegal parameter: %s", $_[0] || "")) },
			SNS_LIMIT_ERROR => sub { shift->throw(2001, sprintf("SNS Limit Error: reset at %s", $_[0] || "")) },
			SNS_ERROR       => sub { shift->throw(2002, sprintf("SNS Error: %s", $_[0] || "SNS Error.")) },
			ERROR           => sub { shift->throw(400, sprintf("%s", $_[0] || "Unknown Error.")) },
		},
	);

	$c->add_trigger(BEFORE_RENDER => $self->can('will_render'));
	$c->add_trigger(AFTER_RENDER => $self->can('did_render'));
	$c->add_trigger(ERROR => $self->can('receive_error'));
	$c->add_trigger(SERVER_ERROR => $self->can('receive_server_error'));

	$self->type('text/plain; charset=UTF-8');

	$self->init_plugins($c);
	$self->call_before_trigger($c);
	$self->will_dispatch($c);
	$self->error->flush;
	$self->error->autoflush(1);
}

sub will_dispatch {}

sub init_plugins  {
	my ($self, $c) = @_;
}

sub call_before_trigger {
	my ($self, $c) = @_;
	$c->call_trigger(BEFORE_DISPATCH => $c, $c->request);
}

sub validate {
	my ($self, @rules) = @_;
	return unless @rules;

	my $validator = Dwarf::Validator->new($self->c->req)->check(@rules);
	if ($validator->has_error) {
		while (my ($param, $detail) = each %{ $validator->errors }) {
			$self->c->error->LACK_OF_PARAM($param) if $detail->{NOT_NULL};
			$self->c->error->INVALID_PARAM($param);
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

sub receive_error {
	my ($self, $c, $error) = @_;
	return $error;
}

sub receive_server_error {
	my ($self, $c, $error) = @_;
	print STDERR sprintf "[Server Error] %s\n", $error;
	return $error;
}

1;

