use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Test::Mechanize;
use base 'WWW::Mechanize';
use Encode::Guess;

sub reload {
	my $self = shift;
	$self->get($self->uri);
}

sub redirect_ok {
	my $self = shift;
	return $self->max_redirect ? $self->SUPER::redirect_ok(@_) : undef;
}

package Apache2::Request;
sub new { return $_[1]; }

package Apache::SWIT::Test;
use base 'Class::Accessor', 'Class::Data::Inheritable';
use Apache::SWIT::Maker::Conversions;
use Apache::SWIT::Test::Utils;
use Apache::SWIT::Test::Request;
use HTML::Tested::Test;
use Test::More;
use Carp;
use Data::Dumper;
use File::Slurp;
use Apache::TestRequest;
use Encode;
use Apache::SWIT;

BEGIN {
	no strict 'refs';
	no warnings 'redefine';
	*{ "Apache::SWIT::swit_die" } = sub {
		my ($class, $msg, $r, @more) = @_;
		confess "$msg with request:\n" . $r->as_string . "and more:\n"
					. join("\n", map { Dumper($_) } @more);
	};
}

__PACKAGE__->mk_accessors(qw(mech session redirect_request));
__PACKAGE__->mk_classdata('root_location');

sub _Do_Startup {
	package main;
	local $0 = shift;
	do $0 or Carp::confess "# Unable to do $0\: $@";
}

=head1 METHODS

=cut
sub do_startup {
	_Do_Startup("blib/conf/startup.pl");
	_Do_Startup("blib/conf/do_swit_startups.pl");
}

sub new {
	my ($class, $args) = @_;
	$args ||= {};
	if ($ENV{SWIT_HAS_APACHE}) {
		$args->{mech} = Apache::SWIT::Test::Mechanize->new;
	}
	$args->{session} = $args->{session_class}->new;
	my $self = $class->SUPER::new($args);
	$self->root_location("") unless $self->root_location;
	$self->_setup_session(Apache::SWIT::Test::Request->new({
		uri => $self->root_location . "/" }), url_to_make => "");
	return $self;
}

sub new_guitest {
	my $self = shift()->new(@_);
	if ($self->mech) {
		$ENV{MOZ_NO_REMOTE} = 1;
		use IO::CaptureOutput qw(capture);
		{
			local $SIG{__WARN__} = sub {};
			eval "require X11::GUITest";
			die "Unable to use X11::GUITest: $@" if $@;
			X11::GUITest::InitGUITest();
		}
		capture(sub {
			eval "use Mozilla::Mechanize::GUITester";
		});
		confess "Unable to use Mozilla::Mechanize::GUITester: $@" if $@;
		my $m = Mozilla::Mechanize::GUITester->new(quiet => 1
				, visible => 0);
		$self->mech($m);
		$m->x_resize_window(800, 600);
	}
	return $self;
}

sub _setup_session {
	my ($self, $r, %a) = @_;
	$r->pnotes('SWITSession', $self->session);
	$self->session->{_request} = $r;
	$r->uri($a{base_url} || $self->root_location . "/" . $a{url_to_make});
}

sub _direct_render {
	my ($self, $handler_class, %args) = @_;
	my $uri = $self->_find_url_to_go(%args);
	my $r = ($self->redirect_request && !$uri) ? $self->redirect_request
			: Apache::SWIT::Test::Request->new;
	$self->redirect_request(undef);

	my $cp = $r->_param || {};
	$r->set_params($args{param}) if $args{param};
	$cp->{$_} = $r->param($_) for keys %{ $r->_param || {} };
	$r->_param($cp);

	$self->_setup_session($r, %args);
	my $res = $handler_class->swit_render($r);
	$r->run_cleanups;
	return $res;
}

sub _do_swit_update {
	my ($self, $handler_class, $r, %args) = @_;
	$self->_setup_session($r, %args);
	my @res = $handler_class->swit_update($r);
	my $new_r = Apache::SWIT::Test::Request->new;
	if (ref($res[0]) && $res[0]->[2]) {
		$new_r->pnotes("PrevRequestSuppress", $res[0]->[2]);
		confess "# Found errors " . $res[0]->[1]
			if $res[0]->[1] =~ /swit_errors/ && !$args{error_ok};
	}
			
	my $uri = ref($res[0]) ? $res[0]->[1] : $res[0];
	$new_r->parse_url($uri) if $uri;

	if (ref($res[0])) {
		my $p = $r->param;
		$new_r->param($_, $p->{$_}) for keys %$p;
	}

	$self->redirect_request($new_r);
	return @res;
}

sub _make_test_request {
	my ($self, $args) = @_;
	my $r = Apache::SWIT::Test::Request->new({
			_param => $args->{fields} });
	my $b = delete $args->{button};
	$r->param($b->[0], $b->[1]) if ($b);
	return $r;
}

sub _direct_update {
	my ($self, $handler_class, %args) = @_;
	my $r = $self->_make_test_request(\%args);
	my @res = $self->_do_swit_update($handler_class, $r, %args);
	$r->run_cleanups;
	return @res;
}

sub mech_get_base {
	my ($self, $loc) = @_;
	return $self->mech->get($loc) if $loc =~ /^\w+:\/\//;
	$loc = $self->root_location . "/$loc" unless ($loc =~ /^\//);
	my $url = $ENV{APACHE_SWIT_SERVER_URL};
	$url =~ s/\/$//;
	return $self->mech->get($url . $loc);
}

sub _find_url_to_go {
	my ($self, %args) = @_;
	my $res = $args{base_url};
	if ($args{make_url}) {
		my $rl = $self->root_location;
		confess "Please set root_location" unless defined($rl);
		$res = "$rl/" . $args{url_to_make};
	}
	return $res;
}

sub _mech_render {
	my ($self, $handler_class, %args) = @_;
	my $goto = $self->_find_url_to_go(%args) or goto OUT;
	my $p = $args{param} or goto GET_IT;
	my $r = Apache::SWIT::Test::Request->new;
	$r->set_params($args{param}) if $args{param};
	$goto .= "?" . join("&", map { "$_=" . $r->param($_) } $r->param);
GET_IT:
	$self->mech_get_base($goto);
OUT:
	$self->session->request->uri($goto || $self->root_location)
		if $self->session;
	return $self->mech->content;
}

sub _filter_out_readonly {
	my ($self, $args) = @_;
	return if ref($self->mech) eq 'Mozilla::Mechanize::GUITester';
	my $form = $self->mech->current_form or confess "No form found in\n"
			. $self->mech->content;
	delete $args->{fields}->{$_} for grep { $_ } map { $_->name }
		grep { $_->readonly } $form->inputs;
	
	return if delete $args->{no_submit_check};
	my @sub = grep { $_->type eq 'submit' } $form->inputs;
	confess $self->mech->content . "No submit input type found. "
		. "Use no_submit_check if needed\n" unless @sub;
}

sub _mech_update {
	my ($self, $handler_class, %args) = @_;
	delete $args{url_to_make};
	delete $args{error_ok};
	my $b = delete $args{button};
	$args{button} = $b->[0] if $b;
	$self->_filter_out_readonly(\%args);
	$self->mech->submit_form(%args);
	return $self->mech->content;
}

sub _decode_utf8_arr {
	my $arr = shift;
	return $arr if ref($arr) ne 'ARRAY'; # DateTime for example
	for (my $i = 0; $i < @$arr; $i++) {
		my $r = ref($arr->[$i]);
		$arr->[$i] = $r ? $r eq 'ARRAY' ? _decode_utf8_arr($arr->[$i])
						: _decode_utf8($arr->[$i])
				: Encode::decode_utf8($arr->[$i]);

	}
	return $arr;
}

sub _decode_utf8 {
	my $arg = shift;
	($arg->{$_} = ref($arg->{$_}) ? _decode_utf8_arr($arg->{$_})
			: Encode::decode_utf8($arg->{$_})) for (keys %$arg);
	return $arg;
}

sub _direct_ht_render {
	my ($self, $handler_class, %args) = @_;
	my $res = $self->_direct_render($handler_class, %args);
	my @cs = HTML::Tested::Test->check_stash($handler_class->ht_root_class
		, $res, _decode_utf8($args{ht}));
	push @cs, $res if @cs;
	return @cs;
}

sub _mech_ht_render {
	my ($self, $handler_class, %args) = @_;
	my $content = $self->_mech_render($handler_class, %args);
	return HTML::Tested::Test->check_text(
			$handler_class->ht_root_class, $content, $args{ht});
}

sub _direct_ht_update {
	my ($self, $handler_class, %args) = @_;
	my $r = $self->_make_test_request(\%args);
	my $rc = $handler_class->ht_root_class;
	HTML::Tested::Test->convert_tree_to_param($rc, $r, $args{ht});
	HTML::Tested::Test->convert_tree_to_param($rc, $r, $args{param})
		if $args{param};
	return $self->_do_swit_update($handler_class, $r, %args);
}

sub _mech_ht_update {
	my ($self, $handler_class, %args) = @_;
	my $r = Apache::SWIT::Test::Request->new({ _param => $args{fields} });
	HTML::Tested::Test->convert_tree_to_param(
			$handler_class->ht_root_class, $r, $args{ht});
	$args{fields} = $r->_param;
	delete $args{ht};
	delete $args{param};

	if (my $form_number = $args{'form_number'}) {
		$self->mech->form_number($form_number) or confess "No number";
	} elsif (my $form_name = $args{'form_name'}) {
		$self->mech->form_name($form_name) or confess "No form_name";
	}
	goto OUT unless $r->upload;

	my $form = $self->mech->current_form or confess "No form found!";
	confess "Form method is not POST" if uc($form->method) ne "POST";
	confess "Form enctype is not multipart/form-data"
	           if $form->enctype ne "multipart/form-data";

	for my $u (map { $r->upload($_) } $r->upload) {
		my $i = $self->mech->current_form->find_input($u->name)
			or die "Unable to find input for " . $u->name;
		if ($i->can('content')) {
			my $c = read_file($u->fh);
			$i->content($c);
			$i->filename($u->filename);
		} else {
			# Mozilla::Mechanize::Input
			$i->{input}->SetValue($u->filename);
		}
	}
OUT:
	return $self->_mech_update($handler_class, %args);
}

sub _make_test_function {
	my ($class, $handler_class, $op, $url) = @_; 
	return sub {
		my ($self, %a) = @_;
		$a{url_to_make} = $url;
		my $f = $self->mech ? "_mech_$op" : "_direct_$op";
		return $self->$f($handler_class, %a);
	};
}

sub make_aliases {
	my ($class, %args) = @_;
	my %trans = (r => 'render', u => 'update');
	while (my ($n, $v) = each %args) {
		no strict 'refs';
		while (my ($f, $t) = each %trans) {
			my $func = "$n\_$f";
			$func =~ s/[\/\.]/_/g;
			my $url = "$n/$f";
			*{ "$class\::$func" } = 
				$class->_make_test_function($v, $t, $url);
			*{ "$class\::ht_$func" } = 
				$class->_make_test_function($v
						, "ht_$t", $url);
		}
		my $r_func = "ht_$n\_r";
		$r_func =~ s/\//_/g;
		*{ "$class\::ok_$r_func" } = sub {
			my $self = shift;
			my @tre = $self->$r_func(@_);
			my $ftr = shift @tre;
			return ok(1) unless defined($ftr);

			Carp::cluck("# Failed");
			carp("# $ftr " . ($self->mech ? "" : " " . Dumper(\@tre)));
			return ok(0);
		};
	}
}

=head2 $test->ok_follow_link(%args)

See WWW::Mechanize for possible C<%args> values.

Returns 1 on success, C<undef> on failure. -1 in direct test.

=cut
sub ok_follow_link {
	my ($self, %arg) = @_;
	my $res = -1;
	$self->redirect_request(undef);
	$self->with_or_without_mech_do(1, sub {
		$res = isnt($self->mech->follow_link(%arg), undef)
			or carp('# Unable to follow: ' . Dumper(\%arg)
				. "in\n" . $self->mech->content);
	});
	return $res;
}

sub ok_get {
	my ($self, $uri, $status) = @_;
	$self->redirect_request(undef);
	$status ||= 200;
	$self->with_or_without_mech_do(1, sub {
		$self->mech_get_base($uri);
		is($self->mech->status, $status)
			or carp("# Unable to get: $uri");
	});
}

sub content_like {
	my ($self, $qr) = @_;
	$self->with_or_without_mech_do(1, sub {
		like($self->mech->content, $qr) or diag(Carp::longmess());
	});
}

sub with_or_without_mech_do {
	my ($self, $m_tests_cnt, $m_test, $d_tests_cnt, $d_test) = @_;
SKIP: {
	if ($self->mech) {
		$m_test->($self) if $m_test;
		skip "Not in direct test", $d_tests_cnt if $d_tests_cnt;
	} else {
		$d_test->($self) if $d_test;
		skip "Not in apache test", $m_tests_cnt;
	}
};
}

sub reset_db {
	my $self = shift;
	my $md = ASTU_Module_Dir();
	my $db = $ENV{APACHE_SWIT_DB_NAME} or confess "# No db is given";
	return if unlink("/tmp/db_is_clean.$db.$<");

	conv_silent_system("psql -d $db < $md/t/conf/schema.sql");
	Apache::SWIT::DB::Connection->instance->db_handle->{CachedKids} = {};

	my $glof = ASTU_Module_Dir() .'/t/logs/kids_are_clean.*';
	if ($self->mech) {
		unlink($_) for glob($glof);
	}
}

1;
