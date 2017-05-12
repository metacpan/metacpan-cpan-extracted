package t::Test::Project::Model::Cd;

use DBICx::Modeler::Model;

belongs_to( artist => 'Artist::Rock' );

1;
