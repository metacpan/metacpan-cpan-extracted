package DBIx::Class::ResultSet::Faceter::Types;
use MooseX::Types -declare => [qw(
    Order
)];

enum Order,
    (qw/asc desc/);

1;