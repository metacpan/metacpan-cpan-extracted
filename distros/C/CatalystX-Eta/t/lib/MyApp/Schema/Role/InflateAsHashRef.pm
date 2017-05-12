package MyApp::Schema::Role::InflateAsHashRef;

use Moose::Role;

sub as_hashref {
    shift->search_rs( undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } );
}

sub resultset {
    my ( $res, $rname ) = @_;
    $res->result_source->schema->resultset($rname);
}

1;

