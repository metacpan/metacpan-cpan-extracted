package My::Model::O::Product;
use Moose;
extends 'DBIx::Class::Wrapper::Object';
has 'o' => ( is => 'ro' , required => 1 , handles => [ 'id' , 'name' ] );
sub turn_on{
    my ($self) = @_;
    return "Turning on $self";
}

sub activate{
    shift->o()->update({ active => 1});
}

sub deactivate{
    shift->o()->update({ active => 0});
}

1;
