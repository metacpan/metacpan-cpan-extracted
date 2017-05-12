package Ark::Plugin::CSRFDefender;
use strict;
use warnings;
use Ark::Plugin;
use Data::UUID;

has csrf_defender_param_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        shift->class_config->{param_name} || 'csrf_token';
    },
);

has csrf_defender_session_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->class_config->{session_name} || $self->csrf_defender_param_name;
    },
);

has csrf_defender_validate_only => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        exists $self->class_config->{validate_only} ? $self->class_config->{validate_only} : undef;
    },
);

has csrf_defender_error_output => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        shift->class_config->{error_output} || <<'...';
<!doctype html>
<html>
  <head>
    <title>403 Forbidden</title>
  </head>
  <body>
    <h1>403 Forbidden</h1>
    <p>
      Session validation failed.
    </p>
  </body>
</html>
...
    }
);

has csrf_defender_error_code => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        shift->class_config->{error_code} || 403;
    }
);

has csrf_defender_error_action => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        shift->class_config->{error_action} || '';
    }
);

has csrf_defender_filter_form => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        shift->class_config->{filter_form} || undef;
    },
);

my $uuid = Data::UUID->new;
has csrf_token => (
    is     => 'ro',
    isa    => 'Str',
    lazy   => 1,
    default => sub {
        my $c = shift;

        if (my $token = $c->session->get($c->csrf_defender_session_name)) {
            return $token;
        }
        else {
            my $token = $uuid->create_str;
            $c->session->set($c->csrf_defender_session_name => $token);

            return $token;
        }
    },
    predicate => '_has_csrf_token',
);

sub validate_csrf_token {
    my $c = shift;
    my $req = $c->request;
    if ($c->_is_csrf_validation_needed) {
        my $param_token   = $req->param($c->csrf_defender_param_name);
        my $session_token = $c->csrf_token;
        if (!$param_token || !$session_token || ($param_token ne $session_token)) {
            return (); # bad
        }
    }
    return 1; # good
}

sub forward_csrf_error {
    my $c = shift;

    if ($c->csrf_defender_error_action) {
        $c->res->code($c->csrf_defender_error_code);
        $c->forward($c->csrf_defender_error_action);
    }
    else {
        $c->res->code($c->csrf_defender_error_code);
        $c->res->body($c->csrf_defender_error_output);
        $c->res->header('Content-Type', 'text/html; charset=UTF-8');
    }
}

sub _is_csrf_validation_needed {
    my $c = shift;
    my $method = $c->req->method;
    return () if !$method;

    return
        $method eq 'POST'   ? 1 :
        $method eq 'PUT'    ? 1 :
        $method eq 'DELETE' ? 1 : ();
}

sub html_filter_for_csrf {
    my ($c, $html) = @_;

    my $reg = qr/<form\s*.*?\s*method=['"]?post['"]?\s*.*?>/i;
    $html =~ s!($reg)!$1\n<input type="hidden" name="@{[$c->csrf_defender_param_name]}" value="@{[$c->csrf_token]}" />!isg;

    $html;
}

after finalize_body => sub {
    my $c = shift;

    return if $c->res->binary;
    my $html = $c->res->body or return;
    return unless $c->csrf_defender_filter_form;

    $html = $c->html_filter_for_csrf($html);
    $c->res->body($html);
};

around dispatch => sub {
    my $orig = shift;
    my ($c) = @_;

    # surely asign csrf_token
    $c->csrf_token;
    if (!$c->csrf_defender_validate_only && !$c->validate_csrf_token) {
        $c->forward_csrf_error;
    }
    else {
        $orig->(@_);
    }
};

1;
__END__

=encoding utf-8

=head1 NAME

Ark::Plugin::CSRFDefender - CSRF Defender for Ark

=head1 SYNOPSIS

    use Ark::Plugin::CSRFDefender;
    # lib/MyApp.pm
    use_plugins qw(
        CSRFDefender
    );

    # lib/MyApp/Controller/Root.pm
    sub auto :Private {
        my ($self, $c) = @_;

        if (!$c->validate_csrf_token) {
            $self->res->code(403);
            $self->res->body("CSRF ERROR");
            $self->detach;
        }

        ...;

    }

    # lib/MyApp/View/Xslate.pm
    sub render {
        my ($self, $template) = @_;
        my $c = $self->context;

        my $html = $self->xslate->render($template);
        $html = $c->html_filter_for_csrf($html);

        return $html;
    }

=head1 CONFIGURATIONS

=head2 C<< filter_form >>

=head2 C<< validate_only >>

=head1 METHODS

=head2 C<< $c->csrf_token -> Str >>

=head2 C<< $c->validate_csrf_token -> Bool >>

=head2 C<< $c->html_filter_for_csrf($html) -> Str >>

=head1 SEE ALSO

L<Amon2::Plugin::Web::CSRFDefender>, L<Mojolicious::Plugin::CSRFDefender>

=cut
