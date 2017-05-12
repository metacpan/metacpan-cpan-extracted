package CatalystX::Eta::Controller::AutoBase;

use Moose::Role;

requires 'base';

around base => \&AutoBase_around_base;

sub AutoBase_around_base {
    my $orig = shift;
    my $self = shift;

    my ($c) = @_;
    $self->$orig(@_);

    my $config = $self->config;

    $c->stash->{collection} = $c->model( $self->config->{result} );

    if ( exists $config->{result_cond} || exists $config->{result_attr} ) {

        $c->stash->{collection} = $c->stash->{collection}->search( $config->{result_cond}, $config->{result_attr} );

    }
}

1;

