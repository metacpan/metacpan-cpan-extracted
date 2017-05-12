package TestApp::Controller::Simple;
use strict;
use warnings;

use base 'Catalyst::Controller::RequestToken';

sub form : Local : CreateToken {
    my ( $self, $c ) = @_;

    my $html = <<HTML;
<html>
<head></head>
<body>
FORM
<form action="confirm" method="post">
<input type="hidden" name="__token" value="TOKEN"/>
<input type="submit" name="submit" value="submit"/>
</form>
</body>
</html>
HTML

    my $token = $self->token($c);
    $html =~ s/TOKEN/$token/g;
    $c->response->body($html);
}

sub confirm : Local {
    my ( $self, $c ) = @_;

    #$c->detach('error') unless $self->is_valid_token;
    my $html = <<HTML;
<html>
<body>
CONFIRM
<form action="complete" method="post">
<input type="hidden" name="__token" value="REQUEST"/>
<input type="submit" name="submit" value="submit"/>
</form>
</body>
</html>
HTML
    my $token = $c->req->param('__token');
    $html =~ s/REQUEST/$token/g;
    $c->response->body($html);
}

sub complete : Local : ValidateToken {
    my ( $self, $c ) = @_;

    $c->detach('error') unless $self->is_valid_token($c);
    my $html = <<HTML;
<html><body>SUCCESS</body></html>
HTML

    $c->response->body($html);
}

sub error : Local {
    my ( $self, $c ) = @_;

    my $html = <<HTML;
<html><body>INVALID ACCESS</body></html>
HTML

    $c->response->body($html);
}

1;
