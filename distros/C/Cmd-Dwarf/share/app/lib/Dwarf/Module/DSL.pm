package Dwarf::Module::DSL;
use Dwarf::Pragma;
use Dwarf::Data::Validator;
use Dwarf::SQLBuilder;
use Dwarf::Util qw/load_class dwarf_log/;
use Carp qw/croak/;
use Scalar::Util qw/weaken/;

use Dwarf::Accessor {
	ro => [qw/context module/],
	rw => [qw/prefix/]
};

our @FUNC = qw/
	self app c model m
	conf db error e env log debug
	session param parameters
	request req method
	response res status type header headers body
	not_found unauthorized finish redirect
	is_cli is_production
	load_plugin load_plugins
	render dump new_query args
/;

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	dwarf_log 'new DSL';
	return $self;
}

sub DESTROY {
	my $self = shift;
	dwarf_log 'DESTROY DSL';
}

sub init {}

sub _build_prefix  {
	my $self = shift;
	$self->{prefix} ||= $self->c->namespace . '::Model';
}

sub app           { shift->context }
sub c             { shift->context }
sub m             { shift->model(@_) }
sub conf          { shift->c->conf(@_) }
sub db            { shift->c->db(@_) }
sub error         { shift->c->error(@_) }
sub e             { shift->c->error(@_) }
sub env           { shift->c->env }
sub log           { shift->c->log(@_) }
sub debug         { shift->c->debug(@_) }

sub session       { shift->c->session(@_) }
sub param         { shift->c->request->param(@_) }
sub parameters    { shift->c->request->parameters(@_) }
sub request       { shift->c->request(@_) }
sub req           { shift->c->request(@_) }
sub method        { shift->c->method(@_) }
sub response      { shift->c->response(@_) }
sub res           { shift->c->response(@_) }
sub status        { shift->c->status(@_) }
sub type          { shift->c->type(@_) }
sub header        { shift->c->header(@_) }
sub headers       { shift->c->headers(@_) }
sub body          { shift->c->body(@_) }

sub not_found     { shift->c->not_found(@_) }
sub unauthorized  { shift->c->unauthorized(@_) }
sub finish        { shift->c->finish(@_) }
sub redirect      { shift->c->redirect(@_) }
sub is_cli        { shift->c->is_cli(@_) }
sub is_production { shift->c->is_production(@_) }
sub load_plugin   { shift->c->load_plugin(@_) }
sub load_plugins  { shift->c->load_plugins(@_) }
sub render        { shift->c->render(@_) }
sub dump          { shift->c->dump(@_) }

sub new_query     { Dwarf::SQLBuilder->new_query }

sub args {
	my ($self, $rules, $module, $args) = @_;
	croak 'rules must be HashRef' unless ref $rules eq 'HASH';
	my @ret = Dwarf::Data::Validator->validate($rules, $args);
	return wantarray ? ($self, $ret[0]) : $ret[0];
}

sub model {
	my $self = shift;
	my $package = shift;

	my $prefix = $self->prefix;
	unless ($package =~ m/^$prefix/) {
		$package = $prefix . '::' . $package;
	}

	$self->context->models->{$package} //= $self->create_model($package, @_);
}

sub create_model {
	my $self = shift;
	my $package = shift;

	croak "package name must be specified to create model."
		unless defined $package;

	my $prefix = $self->prefix;
	unless ($package =~ m/^$prefix/) {
		$package = $prefix . '::' . $package;
	}

	dwarf_log "create model: $package";

	load_class($package);
	my $model = $package->new(context => $self->context, @_);
	weaken $model->{context};
	$model->init($self->context);
	return $model;
}

sub export_symbols {
	my ($self, $to) = @_;

	no strict 'refs';
	no warnings 'redefine';
	my $super = *{"${to}::ISA"}{ARRAY};
	if ($super && $super->[0]) {
		$self->export_symbols($super->[0]);
	}

	for my $f (@FUNC) {
		*{"${to}::${f}"} = sub {
			# OO インターフェース　で呼ばれた時対策
			shift if defined $_[0] and $_[0] eq $self->module;
			return $self->module if $f eq 'self';
			$self->$f(@_)
		};
	}
}

sub delete_symbols {
	my ($self, $from) = @_;

	no strict 'refs';
	no warnings 'redefine';
	my $super = *{"${from}::ISA"}{ARRAY};
	if ($super && $super->[0]) {
		$self->delete_symbols($super->[0]);
	}

	for my $f (@FUNC) {
		*{"${from}::${f}"} = sub {};
	}
}

1;
