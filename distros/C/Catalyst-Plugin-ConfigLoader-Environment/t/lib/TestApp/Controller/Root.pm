#!/usr/bin/perl
# Root.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package TestApp::Controller::Root;
use base 'Catalyst::Controller';
use Data::Dumper;

__PACKAGE__->config->{namespace} = '';

sub default : Private {
    my ($self, $c) = @_;
    $c->res->body(Dumper($c->config));
}

sub foo : Local {
    my ($self, $c, $varname) = @_;
    my $result = $c->view('TestView')->$varname;
    if (ref $result) {
        local($Data::Dumper::Purity) = 1;
        local($Data::Dumper::Indent) = 0;
        local($Data::Dumper::Varname) = $varname;
        $result = Dumper($c->view('TestView')->quux);
	$result =~ s{1}{};
    }
    $c->res->body($result);
}

sub model : Local {
    my ( $self, $c, $varname ) = @_;
    $c->res->body(Dumper(\%{$c->model('TestModel')}));
}

  
1;
