package MyApp1::Schema;
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_components('Schema::ResultSetAccessors');
__PACKAGE__->load_namespaces();

sub resultset_accessor_map {
    {
        'Source' => 'source_resultset',
    }
}

1;