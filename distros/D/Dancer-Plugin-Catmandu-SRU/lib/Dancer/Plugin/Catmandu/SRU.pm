package Dancer::Plugin::Catmandu::SRU;

=head1 NAME

Dancer::Plugin::Catmandu::SRU - SRU server backed by a searchable Catmandu::Store

=cut

our $VERSION = '0.0503';

use Catmandu::Sane;
use Catmandu;
use Catmandu::Fix;
use Catmandu::Exporter::Template;
use SRU::Request;
use SRU::Response;
use Dancer qw(:syntax);
use Dancer::Plugin;

sub sru_provider {
    my ($path) = @_;

    my $setting = plugin_setting;

    my $content_type = $setting->{content_type} // 'text/xml';

    my $default_record_schema = $setting->{default_record_schema};

    my $record_schemas = $setting->{record_schemas};

    my $record_schema_map = {};
    for my $schema (@$record_schemas) {
        $schema = {%$schema};
        my $identifier = $schema->{identifier};
        my $name = $schema->{name};
        if (my $fix = $schema->{fix}) {
            $schema->{fix} = Catmandu::Fix->new(fixes => $fix);
        }
        $record_schema_map->{$identifier} = $schema;
        $record_schema_map->{$name} = $schema;
    }

    my $bag = Catmandu->store($setting->{store})->bag($setting->{bag});

    my $default_limit = $setting->{limit} // $bag->default_limit;
    my $maximum_limit = $setting->{maximum_limit} // $bag->maximum_limit;

    my $template_options = $setting->{template_options} || {};

    my $database_info = "";
    if ($setting->{title} || $setting->{description}) {
        $database_info .= qq(<databaseInfo>\n);
        for my $key (qw(title description)) {
            $database_info .= qq(<$key lang="en" primary="true">$setting->{$key}</$key>\n) if $setting->{$key};
        }
        $database_info .= qq(</databaseInfo>);
    }

    my $index_info = "";
    if ($bag->can('cql_mapping') and my $indexes = $bag->cql_mapping->{indexes}) { # TODO all Searchable should have cql_mapping
        $index_info .= qq(<indexInfo>\n);
        for my $key (keys %$indexes) {
            my $title = $indexes->{$key}{title} || $key;
            $index_info .= qq(<index><title>$title</title><map><name>$key</name></map></index>\n);
        }
        $index_info .= qq(</indexInfo>);
    }

    my $schema_info = qq(<schemaInfo>\n);
    for my $schema (@$record_schemas) {
        my $title = $schema->{title} || $schema->{name};
        $schema_info .= qq(<schema name="$schema->{name}" identifier="$schema->{identifier}"><title>$title</title></schema>\n);
    }
    $schema_info .= qq(</schemaInfo>);

    my $config_info = qq(<configInfo>\n);
    $config_info .= qq(<default type="numberOfRecords">$default_limit</default>\n);
    $config_info .= qq(<setting type="maximumRecords">$maximum_limit</setting>\n);
    $config_info .= qq(</configInfo>);

    get $path => sub {
        content_type $content_type;

        my $params = params('query');
        my $operation = $params->{operation} // 'explain';

        if ($operation eq 'explain') {
            my $request  = SRU::Request::Explain->new(%$params);
            my $response = SRU::Response->newFromRequest($request);

            my $transport   = request->scheme;
            my $database    = substr request->path, 1;
            my $uri         = request->uri_for(request->path_info);
            my $host        = $uri->host;
            my $port        = $uri->port;
            $response->record(SRU::Response::Record->new(
                recordSchema => 'http://explain.z3950.org/dtd/2.1/',
                recordData   => <<XML,
<explain xmlns="http://explain.z3950.org/dtd/2.1/">
<serverInfo protocol="SRU" method="GET" transport="$transport">
<host>$host</host>
<port>$port</port>
<database>$database</database>
</serverInfo>
$database_info
$index_info
$schema_info
$config_info
</explain>
XML
            ));
            return $response->asXML;
        }
        elsif ($operation eq 'searchRetrieve') {
            my $request  = SRU::Request::SearchRetrieve->new(%$params);
            my $response = SRU::Response->newFromRequest($request);
            if (@{$response->diagnostics}) {
                return $response->asXML;
            }

            my $schema = $record_schema_map->{$request->recordSchema || $default_record_schema};
            unless ($schema) {
                $response->addDiagnostic(SRU::Response::Diagnostic->newFromCode(66));
                return $response->asXML;
            }
            my $identifier = $schema->{identifier};
            my $fix = $schema->{fix};
            my $template = $schema->{template};
            my $layout = $schema->{layout};
            my $cql = $params->{query};
            if ($setting->{cql_filter}) {
                # space before the filter is to circumvent a bug in the Solr
                # 3.6 edismax parser
                $cql = "( $setting->{cql_filter}) and ( $cql)";
            }

            my $first = $request->startRecord // 1;
            my $limit = $request->maximumRecords // $default_limit;
            if ($limit > $maximum_limit) {
                $limit = $maximum_limit;
            }

            my $hits = eval {
                $bag->search(
                    %{ $setting->{default_search_params} || {} },
                    cql_query    => $cql,
                    sru_sortkeys => $request->sortKeys,
                    limit        => $limit,
                    start        => $first - 1,
                );
            } or do {
                my $e = $@;
                if ($e =~ /^cql error/) {
                    $response->addDiagnostic(SRU::Response::Diagnostic->newFromCode(10));
                    return $response->asXML;
                }
                die $e;
            };

            $hits->each(sub {
                my $data = $_[0];
                my $metadata = "";
                my $exporter = Catmandu::Exporter::Template->new(
                    %$template_options,
                    template => $template,
                    file     => \$metadata
                );
                $exporter->add($fix ? $fix->fix($data) : $data);
                $exporter->commit;
                $response->addRecord(SRU::Response::Record->new(
                    recordSchema => $identifier,
                    recordData   => $metadata,
                ));
            });
            $response->numberOfRecords($hits->total);
            return $response->asXML;
        }
        else {
            my $request  = SRU::Request::Explain->new(%$params);
            my $response = SRU::Response->newFromRequest($request);
            $response->addDiagnostic(SRU::Response::Diagnostic->newFromCode(6));
            return $response->asXML;
        }
    };
}

register sru_provider => \&sru_provider;

register_plugin;

1;

=head1 SYNOPSIS

    #!/usr/bin/env perl
     
    use Dancer;
    use Catmandu;
    use Dancer::Plugin::Catmandu::SRU;
     
    Catmandu->load;
    Catmandu->config;
     
    my $options = {};

    sru_provider '/sru', %$options;
     
    dance;

=head1 DESCRIPTION

L<Dancer::Plugin::Catmandu::SRU> is a Dancer plugin to provide SRU services for L<Catmandu::Store>-s that support
CQL (such as L<Catmandu::Store::ElasticSearch>). Follow the installation steps below to setup your own SRU server.

=head1 REQUIREMENTS

In the examples below an ElasticSearch 1.7.2 L<https://www.elastic.co/downloads/past-releases/elasticsearch-1-7-2> server
will be used:

    $ cpanm Dancer Catmandu::SRU Catmandu::Store::ElasticSearch

    $ wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.2.zip
    $ unzip elasticsearch-1.7.2.zip
    $ cd elasticsearch-1.7.2
    $ bin/elasticsearch

=head1 RECORDS

Records stored in the Catmandu::Store can be in any format. Preferably the format should be easy to convert into an
XML format. At a minimum each record contains an identifier '_id'. In the examples below we'll configure the SRU
to serve Dublin Core records:

    $ cat sample.yml
    ---
    _id: 1
    creator:
     - Musterman, Max
     - Jansen, Jan
     - Svenson, Sven
    title:
     - Test record
    ...

=head1 CATMANDU CONFIGURATION

ElasticSearch requires a configuration file to map record fields to CQL terms. Below is a minimal configuration 
required to query for '_id' and 'title' and 'creator' in the ElasticSearch collection:

    $ cat catmandu.yml
    ---
    store:
      sru:
        package: ElasticSearch
        options:
          index_name: sru
          bags:
            data:
              cql_mapping:
                default_index: basic
                indexes:
                  _id:
                    op:
                      'any': true
                      'all': true
                      '=': true
                      'exact': true
                    field: '_id'
                  creator:
                    op:
                      'any': true
                      'all': true
                      '=': true
                      'exact': true
                    field: 'creator'
                  title:
                    op:
                      'any': true
                      'all': true
                      '=': true
                      'exact': true
                    field: 'title'

=head1 IMPORT RECORDS

With the Catmandu configuration files in place records can be imported with the L<catmandu> command:

    # Drop the existing ElasticSearch 'sru' collection
    $ catmandu drop sru

    # Import the sample record
    $ catmandu import YAML to sru < sample.yml

    # Test if the records are available in the 'sru' collection
    $ catmandu export sru

=head1 DANCER CONFIGURATION

The Dancer configuration file 'config.yml' contains basic information for the Catmandu::SRU plugin to work:

    * store - In which Catmandu::Store are the metadata records stored
    * bag   - In which Catmandu::Bag are the records of this 'store' (use: 'data' as default)
    * cql_filter -  A CQL query to find all records in the database that should be made available to SRU
    * default_record_schema - The metadataSchema to present records in 
    * limit - The maximum number of records to be returned in each SRU request
    * maximum_limit - The maximum number of search results to return
    * record_schemas - An array of all supported record schemas
        * identifier - The SRU identifier for the schema (see L<http://www.loc.gov/standards/sru/recordSchemas/>)
        * name - A short descriptive name for the schema
        * fix - Optionally an array of fixes to apply to the records before they are transformed into XML
        * template - The path to a Template Toolkit file to transform your records into this format
    * template_options - An optional hash of configuration options that will be passed to L<Catmandu::Exporter::Template> or L<Template>
    * content_type - Set a custom content type header, the default is 'text/xml'.

Below is a sample minimal configuration for the 'sample.yml' demo above:

    charset: "UTF-8"
    plugins:
        'Catmandu::SRU':
            store: sru
            bag: data
            default_record_schema: dc
            limit: 200
            maximum_limit: 500
            record_schemas:
                -
                    identifier: "info:srw/schema/1/dc-v1.1"
                    name: dc
                    template: dc.tt

=head1 METADATA FORMAT TEMPLATE

For each metadata format a Template Toolkit file needs to exist which translate L<Catmandu::Store> records 
into XML records.  The example below contains an example file to transform 'sample.yml' type records into 
SRU DC:

    $ cat dc.tt
    <srw_dc:dc xmlns:srw_dc="info:srw/schema/1/dc-schema"
               xmlns:dc="http://purl.org/dc/elements/1.1/"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xsi:schemaLocation="info:srw/schema/1/dc-schema http://www.loc.gov/standards/sru/recordSchemas/dc-schema.xsd">
    [%- FOREACH var IN ['title' 'creator' 'subject' 'description' 'publisher' 'contributor' 'date' 'type' 'format' 'identifier' 'source' 'language' 'relation' 'coverage' 'rights'] %]
        [%- FOREACH val IN $var %]
        <dc:[% var %]>[% val | html %]</dc:[% var %]>
        [%- END %]
    [%- END %]
    </srw_dc:dc>

=head1 START DANCER

If all the required files are available, then a Dancer application can be started. See the 'demo' directory of 
this distribution for a complete example:

    $ ls 
    app.pl  catmandu.yml  config.yml  dc.tt
    $ cat app.pl
    #!/usr/bin/env perl
     
    use Dancer;
    use Catmandu;
    use Dancer::Plugin::Catmandu::SRU;
     
    Catmandu->load;
    Catmandu->config;
     
    my $options = {};

    sru_provider '/sru', %$options;
     
    dance;

    # Start Dancer
    $ perl ./app.pl
  
    # Test queries:
    $ curl "http://localhost:3000/sru"
    $ curl "http://localhost:3000/sru?version=1.1&operation=searchRetrieve&query=(_id+%3d+1)"
    $ catmandu convert SRU --base 'http://localhost:3000/sru' --query '(_id = 1)'


=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 CONTRIBUTOR

Vitali Peil, C<< <vitali.peil at uni-bielefeld.de> >>

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 SEE ALSO

L<SRU>, L<Catmandu>, L<Catmandu::Store::ElasticSearch> , L<Catmandu::SRU>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
