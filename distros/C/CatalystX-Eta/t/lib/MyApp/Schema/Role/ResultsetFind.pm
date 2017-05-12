package MyApp::Schema::Role::ResultsetFind;

use Moose::Role;

sub resultset_find {
    my ( $res, @find ) = @_;
    $res->result_source->schema->resultset( $res->result_source->source_name )->find(@find);
}

sub resultset_search {
    my ( $res, @find ) = @_;
    $res->result_source->schema->resultset( $res->result_source->source_name )->search(@find);
}

sub resultset {
    my ( $res, @a ) = @_;
    $res->result_source->schema->resultset(@a);
}

1;

