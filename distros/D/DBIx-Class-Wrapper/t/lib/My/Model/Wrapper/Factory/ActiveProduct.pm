package My::Model::Wrapper::Factory::ActiveProduct;
use Moose;
extends qw/My::Model::Wrapper::Factory::Product/;
sub build_dbic_rs{
    my ($self) = @_;
    return $self->bm->dbic_schema->resultset('Product')->search_rs({ active => 1});
}
1;
