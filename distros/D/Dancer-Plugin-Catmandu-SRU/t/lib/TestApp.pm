package t::lib::TestApp;

use Dancer;
use Dancer::Plugin::Catmandu::SRU;

my @settings = <DATA>;
set plugins => from_yaml("@settings");

sru_provider '/sru';

1;

__DATA__
'Catmandu::SRU':
    store: Hash
    bag: data
    cql_filter: 'submissionstatus exact public'
    default_record_schema: mods
    limit: 200
    maximum_limit: 500
    record_schemas:
        -
            identifier: "info:srw/schema/1/mods-v3.3"
            name: mods
            fix: 
                - nothing()
            template: views/mods.tt
