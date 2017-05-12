use strict;
use warnings;

use Test::More qw/no_plan/;
use Test::Deep grep { !m/blessed/ } @Test::Deep::EXPORT;
use Test::Memory::Cycle;

use t::Test::Project;

sub ok_model {
    my $model_class = shift;
#    ok( $model_class->can( 'model_source' ), "$model_class can't model_source" );
#    ok( my $model_source = $model_class->model_source, "Couldn't get model_source for $model_class" );
#    is( $model_class, $model_source->model_class, "$model_class doesn't match up" );
#    memory_cycle_ok($model_source);
}

package t::Model::Track;

use DBICx::Modeler::Model;

package t::Model::Artist;

use DBICx::Modeler::Model;

after name => sub {
    my $self = shift;
    $self->_model__column_name( 'NAME' ) if @_; # There was a set
};

package t::Model::Artist::Rock;

use DBICx::Modeler::Model;

extends qw/t::Model::Artist/;

package t::Model::Cd;

use DBICx::Modeler::Model;

belongs_to(artist => qw/Artist::Rock/);

package main;

use DBICx::Modeler;

my $schema = t::Test::Project->schema;
#my $modeler = t::Modeler->new( schema => $schema );
my $modeler = DBICx::Modeler->new( schema => $schema, namespace => '+t::Model' );

for (qw/ Artist Artist::Rock Cd Track/ ) {
    ok_model( "t::Model::$_" );
}


ok( my $artist = $modeler->create( Artist => { name => 'apple' } ) );
is( $artist->name, 'apple' );
$artist->name( 'banana' );
is( $artist->name, 'NAME' );

1;
