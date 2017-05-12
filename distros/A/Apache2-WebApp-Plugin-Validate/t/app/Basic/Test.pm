package Basic::Test;

use strict;
use warnings FATAL => 'all';

sub browser {
    my ( $self, $c ) = @_;

    my $result = $c->plugin('Validate')->browser();

    $self->_success($c) if ($result == 0);
}

sub currency {
    my ( $self, $c ) = @_;

    my $result1 = $c->plugin('Validate')->currency('1.99');
    my $result2 = $c->plugin('Validate')->currency('x.99');
    my $result3 = $c->plugin('Validate')->currency('9.999');

    $self->_success($c) if ($result1 == 1 && $result2 == 0 && $result2 == 0);
}

sub date {
    my ( $self, $c ) = @_;

    my $result1 = $c->plugin('Validate')->date('2009-01-01');
    my $result2 = $c->plugin('Validate')->date('20-01-0100');
    my $result3 = $c->plugin('Validate')->date('YYYY-01-01');

    $self->_success($c) if ($result1 == 1 && $result2 == 0 && $result2 == 0);
}

sub date_is_future {
    my ( $self, $c ) = @_;

    my $result1 = $c->plugin('Validate')->date_is_future('2020-02-16');
    my $result2 = $c->plugin('Validate')->date_is_future('2009-01-01');

    $self->_success($c) if ($result1 == 1 && $result2 == 0);
}

sub date_is_past {
    my ( $self, $c ) = @_;

    my $result1 = $c->plugin('Validate')->date_is_past('2020-02-16');
    my $result2 = $c->plugin('Validate')->date_is_past('2009-01-01');

    $self->_success($c) if ($result1 == 0 && $result2 == 1);
}

sub domain {
    my ( $self, $c ) = @_;

    my $result1 = $c->plugin('Validate')->domain('domain.com');
    my $result2 = $c->plugin('Validate')->domain('www.domain.com');

    $self->_success($c) if ($result1 == 1 && $result2 == 0);
}

sub email {
    my ( $self, $c ) = @_;

    my $result1 = $c->plugin('Validate')->email('user@domain.com');
    my $result2 = $c->plugin('Validate')->email('user_domain.com');
    my $result3 = $c->plugin('Validate')->email('user@domain');

    $self->_success($c) if ($result1 == 1 && $result2 == 0 && $result3 == 0);
}

sub integer {
    my ( $self, $c ) = @_;

    my $result1 = $c->plugin('Validate')->integer('1');
    my $result2 = $c->plugin('Validate')->integer('X');
    my $result3 = $c->plugin('Validate')->integer(' ');

    $self->_success($c) if ($result1 == 1 && $result2 == 0 && $result3 == 0);
}

sub html {
    my ( $self, $c ) = @_;

    my $result1 = $c->plugin('Validate')->html('<html> ... </html>');
    my $result2 = $c->plugin('Validate')->html('XXX ... /XXX');

    $self->_success($c) if ($result1 == 1 && $result2 == 0);
}

sub url {
    my ( $self, $c ) = @_;

    my $result1 = $c->plugin('Validate')->url('http://www.domain.com/path/to/file');
    my $result2 = $c->plugin('Validate')->url('https://www.domain.com/path/to/file');
    my $result3 = $c->plugin('Validate')->url('smb://domain.com/path/to/file');

    $self->_success($c) if ($result1 == 1 && $result2 == 1 && $result3 == 0);
}

sub _success {
    my ( $self, $c ) = @_;

    $c->request->content_type('text/html');

    print "success";
    exit;
}

1;
