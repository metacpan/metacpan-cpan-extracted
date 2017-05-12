package MyDBIC::View::Excel;
use strict;
use warnings;
use base qw( CatalystX::CRUD::View::Excel );
use CatalystX::CRUD::YUI;

sub get_template_params {
    my ( $self, $c ) = @_;
    my $cvar = $self->config->{CATALYST_VAR} || 'c';
    return (
        $cvar => $c,
        %{ $c->stash },
        yui => CatalystX::CRUD::YUI->new,
    );
}

1;

