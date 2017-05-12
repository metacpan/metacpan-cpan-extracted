package TestApp;

use strict;
use Catalyst qw/MortalForward/;

our $VERSION = '0.01';
TestApp->config( name => 'TestApp', root => '/highlander/rox' );
TestApp->setup;

sub ok : Local { $_[1]->res->header('X-Test' => 'ok') }

sub test : Local {
    my ($self, $c) = @_;
    my @result;
    for (qw/i_die i_live i_live_and_i_die i_die_and_i_live/) {
        eval { $c->forward($_); };
        push @result, $@ ? "failure $_" : "life is beautiful";
    }
    $c->res->header('X-Test' => join "/", @result);
}

sub i_die : Local {
    die "too bad";
}

sub i_live : Private {
    my ($self, $c) = @_;
    $c->res->header('X-Chouette' => 1);
}

sub i_live_and_i_die : Global {
    my ($self, $c) = @_;
    $c->forward('i_live');
    $c->forward('i_die');
}

sub i_die_and_i_live : Global {
    my ($self, $c) = @_;
    $c->forward('i_die');
    $c->forward('i_live');
}

sub class_fwd : Local {
    my ($self, $c) = @_;
    $c->forward('TestApp::C::Elsewhere', 'test');
    $c->res->header('X-Alive' => "yes"); 
}

1;
