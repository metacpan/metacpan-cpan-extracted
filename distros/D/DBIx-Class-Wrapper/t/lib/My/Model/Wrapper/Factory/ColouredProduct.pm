package My::Model::Wrapper::Factory::ColouredProduct;
use Moose;
extends qw/My::Model::Wrapper::Factory::Product/;
sub build_dbic_rs{
  my ($self) = @_;
  my $bm = $self->bm();
  return $bm->dbic_schema->resultset('Product')->search_rs({ colour => $bm->colour() });
};
1;
