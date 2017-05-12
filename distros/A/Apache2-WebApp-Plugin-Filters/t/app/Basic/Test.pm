package Basic::Test;

use strict;
use warnings FATAL => 'all';

sub encode_url {
    my ( $self, $c ) = @_;

    my $result = $c->plugin('Filters')->encode_url('http://domain.com/index.html?name=value');

    $self->_success($c) if ($result =~ /http%3A%2F%2Fdomain%2Ecom%2Findex%2Ehtml%3Fname%3Dvalue/);
}

sub decode_url {
    my ( $self, $c ) = @_;

    my $result = $c->plugin('Filters')->decode_url('http%3A%2F%2Fdomain.com%2Findex.html%3Fname%3Dvalue');

    $self->_success($c) if ($result =~ /http:\/\/domain\.com\/index\.html\?name=value/);
}

sub strip_domain_alias {
    my ( $self, $c ) = @_;

    my $result = $c->plugin('Filters')->strip_domain_alias('www.domain.com');

    $self->_success($c) if ($result eq 'domain.com');
}

sub strip_html {
    my ( $self, $c ) = @_;

    my $result = $c->plugin('Filters')->strip_html('<html>test</html>');

    $self->_success($c) if ($result eq 'test');
}

sub untaint_html {
    my ( $self, $c ) = @_;

    my $result = $c->plugin('Filters')->untaint_html('<none>test</none>');

    $self->_success($c) if ($result eq 'test');
}

sub _success {
    my ( $self, $c ) = @_;

    $c->request->content_type('text/html');

    print "success";
    exit;
}

1;
