package Example::Model::Root::OmitBody;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';
content_type 'application/x-www-form-urlencoded';

has omit_scalar => (is=>'ro', property=>+{omit_empty=>0});
has omit_array => (is=>'ro', property=>+{indexed=>1, omit_empty=>0, model=>'OmitArray'});  

__PACKAGE__->meta->make_immutable();

package Example::Model::Root::OmitArray;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';
content_type 'application/x-www-form-urlencoded';

has test => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();

