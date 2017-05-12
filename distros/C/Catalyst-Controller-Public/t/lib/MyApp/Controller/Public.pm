package MyApp::Controller::Public;

use Moose;
use MooseX::MethodAttributes;

extends  'Catalyst::Controller::Public';


__PACKAGE__->meta->make_immutable;
#__PACKAGE__->config();
