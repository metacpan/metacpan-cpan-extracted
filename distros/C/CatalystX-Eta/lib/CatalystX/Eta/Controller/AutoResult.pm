package CatalystX::Eta::Controller::AutoResult;

use Moose::Role;

with 'CatalystX::Eta::Controller::AutoResultGET';
with 'CatalystX::Eta::Controller::AutoResultPUT';
with 'CatalystX::Eta::Controller::AutoResultDELETE';

1;
