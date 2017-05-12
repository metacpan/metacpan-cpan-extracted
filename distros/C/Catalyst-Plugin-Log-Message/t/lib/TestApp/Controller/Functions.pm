package TestApp::Controller::Functions;

use strict;
use base qw/Catalyst::Controller/;
use Data::Dumper;

sub begin : Private {
    my ($self, $c) = @_;

    my $res = $c->forward('gen_errors');
}

sub last_error : Local {
    my ($self, $c) = @_;

    $c->res->body($c->logger->retrieve_last->message);
}

sub whole_stack : Local {
    my ($self, $c) = @_;

    $c->res->body($c->logger->stack_as_string);
}

sub only_debug : Local {
    my ($self, $c) = @_;

    my @debug = $c->logger->retrieve('debug');
    $c->res->body($debug[0]->message);
}

sub gen_errors : Private {
    my ($self, $c) = @_;
    $c->logger->debug('debug');
    $c->logger->debug('another_debug');
    $c->logger->debug('Error');
}

sub other_debug : Local {
    my ($self, $c) = @_;
    my @debug = $c->logger->retrieve('debug');
    $c->res->body($debug[1]->message);
}


1;
