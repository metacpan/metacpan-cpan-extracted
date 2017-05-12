package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst 5.80;
use CatalystX::RoleApplicator;

extends 'Catalyst';

use Catalyst qw/
    Session
    Session::Store::File
    Session::State::Cookie
/;


__PACKAGE__->config(
    'TraitFor::Request::PerLanguageDomains' => {
        default_language => 'de',
        selectable_language => ['de','en'],
    }
);

__PACKAGE__->apply_request_class_roles(qw/
    Catalyst::TraitFor::Request::PerLanguageDomains
/);

__PACKAGE__->setup;

1;

