package CatalystX::Temporal::Controller::AutoBase;

use Moose::Role;

requires 'base';

around base => \&AutoBase_around_base;

sub AutoBase_around_base {
    my $orig = shift;
    my $self = shift;

    my ($c) = @_;
    $self->$orig(@_);

    my $config = $self->config;
    my $name   = $config->{data_related_as};

    $c->stash->{base_collection} = $c->model( $config->{base_resultset} )->search(
        undef,
        {
            prefetch => ['created_by']
        }
    );

    if ( $c->req->params->{with_deleted} ) {
        $c->stash->{base_collection} = $c->stash->{base_collection}->search(
            {
                'me.deleted_at' => { '!=' => 'infinity' }
            }
        );
    }
    else {
        $c->stash->{base_collection} = $c->stash->{base_collection}->search(
            {
                'me.deleted_at' => 'infinity'
            },
            {
                prefetch => { $name => [ 'created_by', 'deleted_by' ] }
            }
        );
    }

    $c->stash->{collection} = $c->stash->{base_collection}->search(
        undef,
        {
            prefetch => $config->{data_related_as}
        }
    );

    $c->stash->{data_collection} = $c->model( $config->{base_resultset} )->search_related($name);

}

1;

