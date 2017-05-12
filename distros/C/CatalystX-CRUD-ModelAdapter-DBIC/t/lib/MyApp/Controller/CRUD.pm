package MyApp::Controller::CRUD;
use strict;
use warnings;
use base qw( CatalystX::CRUD::Test::Controller );
use Carp;
use Data::Dump;
use MyForm;

__PACKAGE__->config(
    form_class       => 'MyForm',
    form_fields      => [qw( title trackid )],
    init_form        => 'init_with_track',
    init_object      => 'track_from_form',
    default_template => 'no/such/file',
    model_name       => 'Main',
    model_adapter    => 'MyModelAdapter',
    model_meta       => {
        dbic_schema    => 'Track',
        resultset_opts => {
            join     => { track_cds => 'cd' },
            prefetch => { track_cds => 'cd' }
        }
    },
    primary_key           => 'trackid',
    view_on_single_result => 0,
    page_size             => 50,
    allow_GET_writes      => 0,
);

sub serialize_object {
    my ( $self, $c, $object ) = @_;
    my $fields = $c->stash->{form}->fields;
    my $serial = {};
    for my $f (@$fields) {
        if ( $f eq 'cd' && defined $object->$f ) {
            $serial->{$f} = $object->$f->cdid;
        }
        else {
            $serial->{$f} = $object->$f;
        }
    }
    return Data::Dump::dump($serial);
}

# iterator
sub test2 : Local {
    my ( $self, $c ) = @_;

    my $count = 0;

    my $rs = $self->do_model( $c, 'iterator' );
    while ( my $track = $rs->next ) {

        #        $self->serialize_object( $c, $track );
        #        warn sprintf(
        #            "cd title = %s  cd id = %d\n",
        #            $track->cds->first->title,
        #            $track->cds->first->cdid
        #        );
        $count++;
    }

    $c->res->body($count);
}

# search
sub test3 : Local {
    my ( $self, $c ) = @_;

    my $count = 0;
    my @results = $self->do_model( $c, 'search' );
    for my $r (@results) {

        #$self->serialize_object( $c, $r );
        $count++;
    }

    $c->res->body($count);
}

# count
sub test4 : Local {
    my ( $self, $c ) = @_;
    my $count = $self->do_model( $c, 'count' );
    $c->res->body($count);
}

1;
