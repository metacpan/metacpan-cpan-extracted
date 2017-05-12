package CatalystX::Eta::Controller::SimpleCRUD;

use Moose::Role;

# keep in order!!
with 'CatalystX::Eta::Controller::AutoBase';      # 1
with 'CatalystX::Eta::Controller::AutoObject';    # 2
with 'CatalystX::Eta::Controller::AutoResult';    # 3

with 'CatalystX::Eta::Controller::CheckRoleForPUT';
with 'CatalystX::Eta::Controller::CheckRoleForPOST';

with 'CatalystX::Eta::Controller::AutoList';      # 1
with 'CatalystX::Eta::Controller::Search';        # 2

1;

