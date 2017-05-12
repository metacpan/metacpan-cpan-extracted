package TestApp;

use strict;
use warnings;
use MRO::Compat;

use Catalyst;

our $VERSION = '0.01';
__PACKAGE__->config({
    name => 'TestApp',
    disable_component_resolution_regex_fallback => 1,
    'View::RDF' => {
        nodeid_prefix => 'a:',
        nss => { foaf => 'http://xmlns.com/foaf/0.1/' },
        encoding => 'utf-8'
    },
});

__PACKAGE__->setup;

sub finalize_error {
    my $c = shift;
    $c->res->header('X-Error' => $c->error->[0]);
    $c->next::method;
}

1;
