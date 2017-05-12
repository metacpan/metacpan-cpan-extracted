package Dwarf::Plugin::CSRFDefender;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method random_string read_file/;
use Carp;
use Time::HiRes;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	my $form_regexp = $conf->{post_only} ? qr{<form\s*.*?\s*method=['"]?post['"]?\s*.*?>}is : qr{<form\s*.*?>}is;

	unless ($conf->{no_html_filter}) {
		$c->add_trigger('AFTER_RENDER' => sub {
			my ($controller, $c, $out) = @_;
			$$out =~ s!($form_regexp)!qq{$1\n<input type="hidden" name="csrf_token" value="} . $c->get_csrf_defender_token . qq{" />}!ge;
			return $out;
		});
	}

	unless ($conf->{no_validate_hook}) {
		$c->add_trigger('BEFORE_DISPATCH' => sub {
			my $self = shift;
			
			if ($self->validate_csrf) {
				return;
			}
			
			my $body = "FORBIDDEN";
			my $type = "text/plain";

			my $tmpl = $self->base_dir . '/tmpl/403.html';
			if (-f $tmpl) {
				$type = 'text/html';
				$body = read_file($tmpl);
			}

			$self->type($type);
			$self->body($body);
			$self->finish;
		});
	}

	add_method($c, get_csrf_defender_token => sub {
		my $self = shift;
		
		my $token;
		if ($token = $self->session->get('csrf_token')) {
			return $token;
		}

		$token = random_string(32);
		$self->session->set('csrf_token' => $token);
		return $token;
	});

	add_method($c, validate_csrf => sub {
		my $self = shift;
		
		if ($self->req->method eq 'POST') {
			my $r_token       = $self->req->param('csrf_token') || $self->req->header('x-csrf-token');
			my $session_token = $self->session->get('csrf_token');
			if ( !$r_token || !$session_token || ( $r_token ne $session_token ) ) {
				return 0; # bad
			}
		}

		return 1; # good
	});
}

1;
