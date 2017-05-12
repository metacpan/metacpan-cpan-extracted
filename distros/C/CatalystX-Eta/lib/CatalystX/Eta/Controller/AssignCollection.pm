package CatalystX::Eta::Controller::AssignCollection;

use Moose::Role;

with 'CatalystX::Eta::Controller::Search';
with 'CatalystX::Eta::Controller::AutoBase';
with 'CatalystX::Eta::Controller::AutoObject';
with 'CatalystX::Eta::Controller::CheckRoleForPUT';
with 'CatalystX::Eta::Controller::CheckRoleForPOST';

1;

