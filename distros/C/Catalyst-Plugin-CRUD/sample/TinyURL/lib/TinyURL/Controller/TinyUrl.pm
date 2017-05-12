package TinyURL::Controller::TinyUrl;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Class::Trigger;

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('list');
}

sub create : Local {
    my ( $self, $c ) = @_;
    $c->create($self);
}

#sub read : Local {
#    my ( $self, $c ) = @_;
#    $c->read($self);
#}

#sub update : Local {
#    my ( $self, $c ) = @_;
#    $c->update($self);
#}

#sub delete : Local {
#    my ( $self, $c ) = @_;
#    $c->delete($self);
#}

sub list : Local {
    my ( $self, $c ) = @_;
    $c->list($self);
}

sub setting {
    my ( $self, $c ) = @_;
    my $hash = {
        'name'     => 'tinyurl',
        'model'    => 'CDBI::TinyUrl',
        'primary'  => 'id',
        'columns'  => [qw(disable long_url)],
        'default'  => '/tinyurl/list',
        'template' => {
            'prefix' => 'template/tinyurl/',
            'create' => 'create.tt',
            'read'   => 'read.tt',
            'update' => 'update.tt',
            'delete' => 'delete.tt',
            'list'   => 'list.tt'
        },
    };
    return $hash;
}

1;

