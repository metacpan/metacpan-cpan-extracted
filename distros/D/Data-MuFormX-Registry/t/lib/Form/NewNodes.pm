package Form::NewNodes;

use Moo;
use Data::MuForm::Meta;

extends 'Data::MuForm';

has [qw/example1 example2/] => (is=>'ro', required=>1);

has_field 'nodes' => (
  type => 'Text',
  required => 1 );

1;
