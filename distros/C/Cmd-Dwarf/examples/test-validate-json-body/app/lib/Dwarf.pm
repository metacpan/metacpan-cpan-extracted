package Dwarf;
use Dwarf::Pragma;
use Dwarf::Error;
use Dwarf::Message;
use Dwarf::Request;
use Dwarf::Response;
use Dwarf::Trigger;
use Dwarf::Util qw/capitalize read_file filename installed load_class dwarf_log/;
use Cwd 'abs_path';
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';
use Module::Find;
use Router::Simple;
use Scalar::Util qw/weaken/;

our $VERSION = '1.83';

use constant {
	BEFORE_DISPATCH    => 'before_dispatch',
	DISPATCHING        => 'dispatching',
	AFTER_DISPATCH     => 'after_dispatch',
	FINISH_DISPATCHING => 'Dwarf Finish Dispatching Message',
	ERROR              => 'error',
	NOT_FOUND          => 'not_found',
	SERVER_ERROR       => 'server_error',
};

use Dwarf::Accessor {
	ro => [qw/namespace base_dir env config error request response router handler handler_class ext models state/],
	rw => [qw/stash request_handler_prefix request_handler_method/],
};

sub _build_config {
	my $self = shift;
	$self->{config} ||= do {
		my $class = join '::', $self->namespace, 'Config';
		$class .= '::' . ucfirst $self->config_name if $self->can('config_name');
		load_class($class);
		my $config = $class->new(context => $self);
		weaken($config->{context});
		$config;
	};
}

sub _build_error {
	my $self = shift;
	$self->{error} ||= Dwarf::Error->new;
}

sub _build_request {
	my $self = shift;
	$self->{request} ||= do {
		my $req = Dwarf::Request->new($self->env);

		if (defined $req->param('debug')) {
			require CGI::Carp;
			CGI::Carp->import('fatalsToBrowser');
		}

		$req;
	};
}

sub _build_response {
	my $self = shift;
	$self->{response} ||= do {
		my $res = Dwarf::Response->new(200);
		$res->content_type('text/plain');
		$res;
	};
}

sub _build_router { Router::Simple->new }

sub new {
	my $invocant = shift;
	my $class = ref $invocant || $invocant;
	my $self = bless { @_ }, $class;
	dwarf_log 'new Dwarf';
	$self->init;
	return $self;
}

sub DESTROY {
	my $self = shift;
	dwarf_log 'DESTROY Dwarf';
}

sub init {
	my $self = shift;

	$self->{env}                    ||= {};
	$self->{namespace}              ||= ref $self;
	$self->{base_dir}               ||= abs_path(catfile(dirname(filename($self)), '..'));
	$self->{models}                 ||= {};
	$self->{state}                  ||= BEFORE_DISPATCH;
	$self->{stash}                  ||= {};
	$self->{request_handler_prefix} ||= join '::', $self->namespace, 'Controller';
	$self->{request_handler_method} ||= 'any';

	$self->setup;
	$self->add_routes;
}

sub add_routes {
	my $self = shift;
	$self->router->connect("/dwarf/test/api/*", { controller => "Dwarf::Test::Controller::Api" });
	$self->router->connect("/api/*", { controller => "Api" });
	$self->router->connect("/cli/*", { controller => "Cli" });
	$self->router->connect("*", { controller => "Web" });
}

sub setup {}

sub is_production { 1 }

sub is_cli {
	my $self = shift;
	my $server_software = $self->env->{SERVER_SOFTWARE} || '';
	return $server_software eq 'Plack::Handler::CLI';
}

sub param   { shift->request->param(@_) }
sub req     { shift->request(@_) }
sub res     { shift->response(@_) }
sub status  { shift->res->status(@_) }
sub type    { shift->res->content_type(@_) }
sub header  { shift->res->header(@_) }
sub headers { shift->res->headers(@_) }
sub body    { shift->res->body(@_) }

sub method  {
	my $self = shift;
	return uc($self->param('_method') || $self->request->method(@_))
}

sub conf {
	my $self = shift;
	return $self->config->get(@_) if @_ == 1;
	return $self->config->set(@_);
}

sub dump {
	my $self = shift;
	local $Data::Dumper::Indent = 1;
	local $Data::Dumper::Terse  = 1;
	Data::Dumper->Dump([@_]);
}

sub to_psgi {
	my $self = shift;
	$self->call_before_trigger;
	$self->dispatch(@_);
	$self->call_after_trigger;
	return $self->finalize;
}

sub dispatch {
	my $self = shift;

	dwarf_log 'dispatch Dwarf';

	eval {
		eval {
			my $p = $self->router->match($self->env);
			#warn Dumper $p;
			return $self->handle_not_found unless $p;

			my $controller = delete $p->{controller};
			my $action = delete $p->{action};
			my $splat = delete $p->{splat};

			# 余ったパラメータを追加
			for my $k (keys %{ $p }) {
				$self->request->parameters->add($k, $p->{$k});
			}

			# prefix がなかったら補完する
			if ($controller) {
				($controller) = $self->find_class($controller);
			}

			# splat があったら、splat から controller を組み立てる
			if ($splat) {
				my @a = grep { $_ ne "/" } @{ $splat };
				unshift @a, $controller if $controller;
				my ($class, $ext) = $self->find_class(join "/", @a);
				$controller = $class if $class;
			}

			return $self->handle_not_found unless $controller;
			Dwarf::Util::load_class($controller);

			$self->{handler_class} = $controller;
			$self->{handler} = $controller->new(context => $self);
			weaken($self->{handler}->{context});

			my $method = $self->find_method;
			return $self->not_found unless $method;

			# プロセス名に処理中のコントローラー名を表示する
			$self->proctitle(sprintf "[Dwarf] %s::%s() (%s)", $controller, lc $self->method, $self->base_dir);

			$self->handler->init($self);
			
			my $body = $self->handler->$method($self, @_);
			$self->body($body);

			$self->handler->did_dispatch($self, $body);
		};
		if ($@) {
			my $error = $@;
			$@ = undef;

			if ($error =~ /Can't locate .+\.pm in/) {
				print STDERR $error . "\n";
				return $self->not_found;
			}

			if (ref $error eq 'Dwarf::Error') {
				return $self->handle_error($error);
			}

			die $error;
		}
	};
	if ($@) {
		my $error = $@;
		$@ = undef;

		if (ref $error eq 'Dwarf::Message') {
			if ($error->name eq FINISH_DISPATCHING) {
				return $self->body($error->data);
			}
		}

		return $self->handle_server_error($error);
	}
}

sub finalize {
	my $self = shift;

	dwarf_log 'finalize Dwarf';

	if ($self->can('disconnect_db')) {
		$self->disconnect_db;
	}

	# プロセス名を idle にする
	$self->proctitle(sprintf "[Dwarf] idle (%s)", $self->base_dir);

	my $res = ref $self->body eq 'CODE'
		? $self->body # ストリーミング
		: $self->response->finalize;

	return $res;
}

sub finish {
	my ($self, $body) = @_;
	$body //= '';
	my $message = Dwarf::Message->new(
		name => FINISH_DISPATCHING,
		data => $body,
	);
	die $message;
}

sub redirect {
	my ($self, $to, $code) = @_;
	$code ||= 302;
	$self->response->redirect($to, $code);
	$self->finish;
	return;
}

sub not_found {
	my $self = shift;
	$self->handle_not_found(@_);
	$self->finish;
}

sub handle_not_found {
	my ($self) = @_;
	$self->{response} = $self->req->new_response;
	$self->status(404);

	my @code = $self->get_trigger_code('NOT_FOUND');
	for my $code (@code) {
		my $body = $code->($self->_make_args);
		next unless $body;
		return $self->body($body);
	}

	my $body = "NOT FOUND";
	my $type = "text/plain";

	my $tmpl = $self->base_dir . '/tmpl/404.html';
	if (-f $tmpl) {
		$type = 'text/html';
		$body = read_file($tmpl);
	}

	$self->type($type);
	$self->body($body);
}

sub unauthorized {
	my $self = shift;
	$self->handle_unauthorized(@_);
	$self->finish;
}

sub handle_unauthorized {
	my ($self) = @_;
	$self->{response} = $self->req->new_response;
	$self->status(401);

	my @code = $self->get_trigger_code('UNAUTHORIZED');
	for my $code (@code) {
		my $body = $code->($self->_make_args);
		next unless $body;
		return $self->body($body);
	}

	my $body = "UNAUTHORIZED";
	my $type = "text/plain";

	my $tmpl = $self->base_dir . '/tmpl/401.html';
	if (-f $tmpl) {
		$type = 'text/html';
		$body = read_file($tmpl);
	}

	$self->type($type);
	$self->body($body);
}

sub handle_error {
	my ($self, $error) = @_;
	$self->status(400);

	my @code = $self->get_trigger_code('ERROR');
	for my $code (@code) {
		my $body = $code->($self->_make_args($error));
		next unless $body;
		return $self->body($body);
	}

	$self->receive_error($error);
}

sub handle_server_error {
	my ($self, $error) = @_;
	$self->status(500);

	my @code = $self->get_trigger_code('SERVER_ERROR');
	for my $code (@code) {
		my $body = $code->($self->_make_args($error));
		next unless $body;
		return $self->body($body);
	}

	$self->receive_server_error($error);
}

sub receive_error { die $_[1] }
sub receive_server_error { die $_[1] }

sub find_class {
	my ($self, $path, $prefix) = @_;
	return if not defined $path or $path eq '';

	$path =~ s|^/||;
	$path =~ s/\.(.*)$//;
	my $ext = $1;
	$self->{ext} = $1;

	my $class = join '::', map { capitalize($_) } grep { $_ ne '' } split '\/', $path;

	$prefix ||= $self->request_handler_prefix;

	if (defined $prefix and $prefix ne '') {
		if ($class !~ /^$prefix/) {
			$class = join '::', $prefix, $class;
		}
	}

	return ($class, $ext);
}

sub find_method {
	my ($self) = @_;
	my $request_method = $self->method;
	$request_method = lc $request_method if defined $request_method;
	return unless $request_method =~ /^(get|post|put|delete|options|patch|trace|link|unlink)$/;
	return sub {} if $request_method eq 'options'; # for preflight request (CORS)
	return $self->handler->can($request_method)
		|| $self->handler->can($self->request_handler_method);
}

sub model {
	my $self = shift;
	my $package = shift;

	my $prefix = $self->namespace . '::Model';
	unless ($package =~ m/^$prefix/) {
		$package = $prefix . '::' . $package;
	}

	$self->models->{$package} //= $self->create_module($package, @_);
}

sub create_module {
	my $self = shift;
	my $package = shift;

	die "package name must be specified to create module."
		unless defined $package;

	my $prefix = $self->namespace;
	unless ($package =~ m/^$prefix/) {
		$package = $prefix . '::' . $package;
	}

	load_class($package);
	my $module = $package->new(context => $self, @_);
	weaken $module->{context};
	$module->init($self);
	return $module;
}

sub proctitle {
	my ($self, $title) = @_;
	$title ||= $0;

	if ($^O eq 'linux' and load_class("Sys::Proctitle")) {
		Sys::Proctitle::setproctitle($title);
		no warnings 'redefine';
		*proctitle = sub { Sys::Proctitle::setproctitle($_[1]) };
		return;
	}
	$0 = $title;
}

sub call_before_trigger {
	my $self = shift;
	if ($self->state eq BEFORE_DISPATCH) {
		$self->call_trigger(BEFORE_DISPATCH => $self, $self->request);
		$self->{state} = DISPATCHING;
	}
}

sub call_after_trigger {
	my $self = shift;
	if ($self->state eq DISPATCHING) {
		$self->call_trigger(AFTER_DISPATCH => $self, $self->response);
		$self->{state} = AFTER_DISPATCH;
	}
}

sub load_plugins {
	my ($class, @args) = @_;

	while (@args) {
		my $module = shift @args;
		my $conf = shift @args;
		next unless defined $module;
		$class->load_plugin($module, $conf);
	}
}

sub load_plugin {
	my ($class, $module, $conf) = @_;
	if (installed($module, 'App::Plugin')) {
		$module = load_class($module, 'App::Plugin');
	} else {
		$module = load_class($module, 'Dwarf::Plugin');
	}
	$module->init($class, $conf);
}

sub _make_args {
	my $self = shift;
	my @args;
	push @args, $self->handler if defined $self->handler;
	push @args, $self;
	push @args, @_;
	return @args;
}

1;
__END__

=encoding utf-8

=head1 NAME

Dwarf - Web Application Framework (Perl5)

=head1 SYNOPSIS

    use Dwarf;

=head1 DESCRIPTION

this is a development repo for Dwarf

Dwarf
https://github.com/seagirl/dwarf.git

=head1 LICENSE

Copyright (C) Takuho Yoshizu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takuho Yoshizu E<lt>yoshizu@s2factory.co.jpE<gt>

=cut
