package Amon2::Plugin::Web::CSRFDefender;
use 5.008001;
use strict;
use warnings;

our $VERSION = "7.03";

use Amon2::Util ();
use Amon2::Plugin::Web::CSRFDefender::Random;

our $ERROR_HTML = <<'...';
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

sub init {
    my ($class, $c, $conf) = @_;

    my $form_regexp = $conf->{post_only} ? qr{<form\s*.*?\s*method=['"]?post['"]?\s*.*?>}is : qr{<form\s*.*?>}is;

    unless ($conf->{no_html_filter}) {
        $c->add_trigger(
            HTML_FILTER => sub {
                my ($self, $html) = @_;
                $html =~ s!($form_regexp)!qq{$1\n<input type="hidden" name="csrf_token" value="}.$self->get_csrf_defender_token().qq{" />}!ge;
                return $html;
            },
        );
    }
    unless ($conf->{no_validate_hook}) {
        $c->add_trigger(
            BEFORE_DISPATCH => sub {
                my $self = shift;
                if (not $self->validate_csrf()) {
                    return $self->create_response(
                        403,
                        [
                            'Content-Type'   => 'text/html',
                            'Content-Length' => length($ERROR_HTML)
                        ],
                        $ERROR_HTML
                    );
                } else {
                    return;
                }
            }
        );
    }
    my $csrf_token_generator = $conf->{csrf_token_generator} || \&Amon2::Plugin::Web::CSRFDefender::Random::generate_session_id;
    Amon2::Util::add_method($c, 'get_csrf_defender_token', sub {
        my $self = shift;
        if (my $token = $self->session->get('csrf_token')) {
            $token;
        } else {
            my $token = $csrf_token_generator->($self);
            $self->session->set('csrf_token' => $token);
            $token;
        }
    });
    Amon2::Util::add_method($c, 'validate_csrf', \&validate_csrf);
}

sub validate_csrf {
    my $self = shift;

    if ( $self->req->method eq 'POST' ) {
        my $r_token       = $self->req->param('csrf_token') || $self->req->header('x-csrf-token');
        my $session_token = $self->session->get('csrf_token');
        if ( !$r_token || !$session_token || ( $r_token ne $session_token ) ) {
            return 0; # bad
        }
    }
    return 1; # good
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Plugin::Web::CSRFDefender - Anti CSRF filter

=head1 SYNOPSIS

    package MyApp::Web;
    use Amon2::Web;

    __PACKAGE__->load_plugin('Web::CSRFDefender');

=head1 DESCRIPTION

This plugin denies CSRF request.

Do not use this with L<HTTP::Session2>. Because L<HTTP::Session2> has XSRF token management function by itself.

=head1 METHODS

=over 4

=item $c->get_csrf_defender_token()

Get a CSRF defender token. This method is useful to add token for AJAX request.

=item $c->validate_csrf()

You can validate CSRF token manually.

=back

=head1 PARAMETERS

=over 4

=item no_validate_hook

Do not run validation automatically.

=item no_html_filter

Disable HTML rewriting filter. By default, CSRFDefender inserts XSRF token for each form element.

It's very useful but it hits performance issue if your site is very high traffic.

=item csrf_token_generator

You can change the csrf token generation algorithm.

=back

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 THANKS TO

Kazuho Oku and mala for security advice.

=head1 SEE ALSO

L<Amon2>

=cut

