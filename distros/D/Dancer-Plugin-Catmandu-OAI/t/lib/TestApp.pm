package t::lib::TestApp;

use Dancer;
use Dancer::Plugin::Catmandu::OAI;

my @settings = <DATA>;
set plugins => from_yaml("@settings");

oai_provider '/oai';

1;

__DATA__
'Catmandu::OAI':
    store: Hash
    bag: publication
    datestamp_field: date_updated
    repositoryName: "My OAI Service Provider"
    uri_base: "http://oai.service.com/oai"
    adminEmail: me@example.com
    earliestDatestamp: "1970-01-01T00:00:01Z"
    deletedRecord: persistent
    repositoryIdentifier: oai.service.com
    limit: 200
    delimiter: ":"
    sampleIdentifier: "oai:oai.service.com:1585315"
    metadata_formats:
        -
            metadataPrefix: oai_dc
            schema: "http://www.openarchives.org/OAI/2.0/oai_dc.xsd"
            metadataNamespace: "http://www.openarchives.org/OAI/2.0/oai_dc/"
            template: views/oai_dc.tt
            cql: 'status exact public'
            fix:
              - nothing()
        -
            metadataPrefix: mods
            schema: "http://www.loc.gov/standards/mods/v3/mods-3-0.xsd"
            metadataNamespace: "http://www.loc.gov/mods/v3"
            template: views/mods.tt
            cql: 'submissionstatus exact public'
            fix:
              - nothing()
    sets:
        -
            setSpec: openaccess
            setName: Open Access
            cql: 'oa=1'
        -
            setSpec: journal_article
            setName: Journal article
            cql: 'documenttype exact journal_article'
        -
            setSpec: book
            setName: Book
            cql: 'documenttype exact book'
