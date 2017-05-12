package My::Model::Wrapper::Factory::Product;
use Moose;
extends  qw/DBIx::Class::Wrapper::Factory/ ;

use My::Model::O::Product;

sub wrap{
    my ($self , $o) = @_;
    return My::Model::O::Product->new({o => $o , factory => $self });
}
1;
