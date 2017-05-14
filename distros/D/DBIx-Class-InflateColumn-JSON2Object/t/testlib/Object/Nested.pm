package testlib::Object::NestedTypes;
use Moose;
use Moose::Util::TypeConstraints;
subtype 'ArrayRefIngredients',
as 'ArrayRef[testlib::Object::NestedIngredient]';

coerce 'ArrayRefIngredients',
from 'ArrayRef[HashRef]',
via { [ map { testlib::Object::NestedIngredient->new($_) } @$_ ] };


package testlib::Object::NestedRecipe;
use 5.010;
use Moose;
with 'DBIx::Class::InflateColumn::JSON2Object::Role::Storable';

has 'name' => (
    is=>'ro',
    isa=>'Str',
    required=>1
);

has 'ingredients' => (
    is=>'ro',
    traits  => ['Array'],
    isa=>'ArrayRefIngredients',
    coerce=>1,
    default=>sub { [] },
    handles => {
        add_ingredient     => 'push',
    },
);

package testlib::Object::NestedIngredient;
use 5.010;
use Moose;
with 'DBIx::Class::InflateColumn::JSON2Object::Role::Storable';

has 'name' => (
    is=>'ro',
    isa=>'Str',
    required=>1
);

has 'amount' => (
    is=>'ro',
    isa=>'Str',
    required=>1
);

has 'is_vegan' => (
    is=>'ro',
    isa=>'InflateColumnJSONBool',
    coerce=>1,
);

__PACKAGE__->meta->make_immutable;
