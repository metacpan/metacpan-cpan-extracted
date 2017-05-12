package App::Test;
use Dwarf::Pragma;
use parent 'Exporter';
use Data::Dumper;
use JSON;
use HTTP::Cookies;
use HTTP::Request::Common qw/GET HEAD PUT POST DELETE/;
use Plack::Test;
use Test::More;
use WWW::Mechanize;
use App;

our @EXPORT = qw/is_success is_failure/;

sub import {
	my ($pkg) = @_;
	Dwarf::Pragma->import();
	Test::More->import();
	Test::More->export_to_level(1);
	Plack::Test->import();
	Plack::Test->export_to_level(1);
}

sub is_success {
	my ($res, $path) = @_;
	my $desc = $res->status_line;
	$desc .= ', redirected to ' . ($res->header("Location") || "") if ($res->is_redirect);
	if (!$res->is_redirect) {
		warn Dumper $res unless $res->is_success;
		ok $res->is_success, "$path: $desc";
	} else {
		ok $res->is_redirect, "$path: $desc";
	}
}

sub decode_response {
	my ($res) = @_;
	if (($res->code == 200 || $res->code == 400 || $res->code == 500) and $res->header('Content-Type') =~ /json/) {
		return $res unless $res->content;
		my $content = eval { decode_json($res->content) };
		if ($@) {
			warn $content;
		}
		$res->content($content);
		return $res;
	} elsif ($res->code == 302) {
		return $res;
	}
	return $res;
}

sub is_failure {
	my ($res, $path) = @_;
	my $desc = $res->status_line;
	ok !$res->is_success, "$path: $desc";
}

use Dwarf::Accessor qw/context context_stack cookie_jar mech will_decode_content/;

sub _build_context { App->new }
sub _build_context_stack { [] }

sub _build_cookie_jar { HTTP::Cookies->new }

sub _build_mech {
	my $mech = WWW::Mechanize->new(autocheck => 0);
	$mech->cookie_jar(self->cookie_jar);
	return $mech;
}

sub c { $_[0]->context }

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = bless { @_ }, $class;
	$self->{will_decode_content} //= 0;
	return $self;
}

sub req_ok {
	my ($self, $method, $url, @params) = @_;
	my ($req, $res) = $self->req($method, $url, @params);
	is_success($res, $req->uri);
	return wantarray ? ($req, $res) : $res;
}

sub req_not_ok {
	my ($self, $method, $url, @params) = @_;
	my ($req, $res) = $self->req($method, $url, @params);
	is_failure($res, $req->uri);
	return wantarray ? ($req, $res) : $res;
} 

sub req {
	my ($self, $method, $url, @args) = @_;

	if ($self->c->conf('ssl')) {
		$url =~ s/^http/https/;
	}

	my $uri = URI->new($url);
	$uri->query_form($args[0]) if $method =~ /^(get|delete)$/i;

	my ($req, $res);

	test_psgi app => $self->app, client => sub {
		my ($cb) = @_;

		my @a = ($uri->as_string);
		push @a, @args if $method !~ /^(get|delete)$/i;
		$method = uc $method;
		$method = \&$method;
		$req = $method->(@a);

		$self->cookie_jar->add_cookie_header($req);		
		$res = $cb->($req);
		$self->cookie_jar->extract_cookies($res);
	};

	$res = decode_response($res) if $self->will_decode_content;

	return wantarray ? ($req, $res) : $res;
}

sub mech_fetch {
	my ($self, $url, $args) = @_;
	my $uri = URI->new($url);
	$uri->query_form($args) if ref $args eq 'HASH';

	my $mech = $self->mech;
	$mech->get($uri);
	$mech->update_html(decode_utf8($mech->content));
}

sub mech_ok {
	my ($self, $url, $args) = @_;
	$self->mech_fetch($url, $args);
	ok($self->mech->success);
}

sub mech_not_ok {
	my ($self, $url, $args) = @_;
	$self->mech_fetch($url, $args);
	ok(!$self->mech->success);
}

sub mech_submit {
	my ($self, $url, $args, $opt) = @_;
	my $form_number = $opt->{form_number} // 1;
	$self->mech_fetch($url);
	my $mech = $self->mech;
	$mech->form_number($form_number);
	$mech->set_fields(%$args);
	$mech->click;
	$mech->update_html(decode_utf8($mech->content));
}

sub mech_submit_ok {
	my ($self, $url, $args, $opt) = @_;
	$self->mech_submit($url, $args, $opt);
	my $mech = $self->mech;
	ok($mech->success);
}

sub mech_submit_not_ok {
	my ($self, $url, $args, $opt) = @_;
	$self->mech_submit($url, $args, $opt);
	my $mech = $self->mech;
	ok(!$mech->success);
}

sub app {
	my $self = shift;
	return sub {
		my $env = shift;
		$env->{HTTPS} = 'on';
		$env->{HTTP_HOST} = 'localhost';
		#$env->{HTTP_AUTHORIZATION} = "Bearer " . $self->c->conf('/oauth/bearer_token');
		push @{ $self->{context_stack} }, $self->context if $self->context; # 古いコンテキストを保存して GC されないようにする
		$self->{context} = App->new(env => $env);
		$self->c->runtime(0) if $self->c->can('runtime'); # runtime プラグインの結果を出力しない
		$self->c->to_psgi;
	};
}

1;
