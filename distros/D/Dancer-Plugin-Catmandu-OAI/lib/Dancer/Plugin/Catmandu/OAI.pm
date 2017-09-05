package Dancer::Plugin::Catmandu::OAI;

=head1 NAME

Dancer::Plugin::Catmandu::OAI - OAI-PMH provider backed by a searchable Catmandu::Store

=cut

our $VERSION = '0.0501';

use Catmandu::Sane;
use Catmandu::Util qw(is_string is_array_ref);
use Catmandu;
use Catmandu::Fix;
use Catmandu::Exporter::Template;
use Dancer::Plugin;
use Dancer qw(:syntax);
use DateTime;
use DateTime::Format::ISO8601;
use DateTime::Format::Strptime;
use Clone qw(clone);

my $DEFAULT_LIMIT = 100;

my $VERBS = {
    GetRecord => {
        valid    => {metadataPrefix => 1, identifier => 1},
        required => [qw(metadataPrefix identifier)],
    },
    Identify => {
        valid    => {},
        required => [],
    },
    ListIdentifiers => {
        valid    => {metadataPrefix => 1, from => 1, until => 1, set => 1, resumptionToken => 1},
        required => [qw(metadataPrefix)],
    },
    ListMetadataFormats => {
        valid    => {identifier => 1, resumptionToken => 1},
        required => [],
    },
    ListRecords => {
        valid    => {metadataPrefix => 1, from => 1, until => 1, set => 1, resumptionToken => 1},
        required => [qw(metadataPrefix)],
    },
    ListSets => {
        valid    => {resumptionToken => 1},
        required => [],
    },
};

sub oai_provider {
    my ($path, %opts) = @_;

    my $setting = clone(plugin_setting);

    my $bag = Catmandu->store($opts{store} || $setting->{store})->bag($opts{bag} || $setting->{bag});

    $setting->{granularity} //= "YYYY-MM-DDThh:mm:ssZ";

    # TODO this was for backwards compatibility. Remove?
    if ($setting->{filter}) {
        $setting->{cql_filter} = delete $setting->{filter};
    }

    $setting->{default_search_params} ||= {};

    my $datestamp_parser;
    if ($setting->{datestamp_pattern}) {
        $datestamp_parser = DateTime::Format::Strptime->new(
            pattern  => $setting->{datestamp_pattern},
            on_error => 'undef',
        );
    }

    my $format_datestamp = $datestamp_parser ? sub {
        $datestamp_parser->parse_datetime($_[0])->iso8601.'Z';
    } : sub {
        $_[0];
    };

    $setting->{get_record_cql_pattern} ||= $bag->id_key.' exact "%s"';

    my $metadata_formats = do {
        my $list = $setting->{metadata_formats};
        my $hash = {};
        for my $format (@$list) {
            my $prefix = $format->{metadataPrefix};
            $format = {%$format};
            if (my $fix = $format->{fix}) {
                $format->{fix} = Catmandu::Fix->new(fixes => $fix);
            }
            $hash->{$prefix} = $format;
        }
        $hash;
    };

    my $sets = do {
        if (my $list = $setting->{sets}) {
            my $hash = {};
            for my $set (@$list) {
                my $key = $set->{setSpec};
                $hash->{$key} = $set;
            }
            $hash;
        } else {
            +{};
        }
    };

    my $ns = "oai:$setting->{repositoryIdentifier}:";

    my $branding = "";
    if (my $icon = $setting->{collectionIcon}) {
        if (my $url = $icon->{url}) {
            $branding .= <<TT;
<description>
<branding xmlns="http://www.openarchives.org/OAI/2.0/branding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/branding/ http://www.openarchives.org/OAI/2.0/branding.xsd">
<collectionIcon>
<url>$url</url>
TT
            for my $tag (qw(link title width height)) {
                my $val = $icon->{$tag} // next;
                $branding .= "<$tag>$val</$tag>\n";
            }

            $branding .= <<TT;
</collectionIcon>
</branding>
</description>
TT
        }
    }

    my $xsl_stylesheet = "";
    if (my $xsl_path = $setting->{xsl_stylesheet}) {
        $xsl_stylesheet = "<?xml-stylesheet type='text/xsl' href='$xsl_path' ?>";
    }

    my $template_header = <<TT;
<?xml version="1.0" encoding="UTF-8"?>
$xsl_stylesheet
<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
<responseDate>[% response_date %]</responseDate>
[%- IF params.resumptionToken %]
<request verb="[% params.verb %]" resumptionToken="[% params.resumptionToken %]">[% uri_base %]</request>
[%- ELSE %]
<request[% FOREACH param IN params %] [% param.key %]="[% param.value | xml %]"[% END %]>[% uri_base %]</request>
[%- END %]
TT

    my $template_footer = <<TT;
</OAI-PMH>
TT

    my $template_error = <<TT;
$template_header
[%- FOREACH error IN errors %]
<error code="[% error.0 %]">[% error.1 | xml %]</error>
[%- END %]
$template_footer
TT

    my $template_record_header = <<TT;
<header[% IF deleted %] status="deleted"[% END %]>
    <identifier>${ns}[% id %]</identifier>
    <datestamp>[% datestamp %]</datestamp>
    [%- FOREACH s IN setSpec %]
    <setSpec>[% s %]</setSpec>
    [%- END %]
</header>
TT

    my $template_get_record = <<TT;
$template_header
<GetRecord>
<record>
$template_record_header
[%- UNLESS deleted %]
<metadata>
[% metadata %]
</metadata>
[%- END %]
</record>
</GetRecord>
$template_footer
TT

    my $admin_email = $setting->{adminEmail} // [];
    $admin_email = [$admin_email] unless is_array_ref($admin_email);
    $admin_email = join('', map { "<adminEmail>$_</adminEmail>" } @$admin_email);

    my @identify_extra_fields;
    for my $i_field (qw(description compression)){
        my $i_value = $setting->{$i_field} // [];
        $i_value = [$i_value] unless is_array_ref($i_value);
        push @identify_extra_fields, join('', map { "<$i_field>$_</$i_field>" } @$i_value);
    }

    my $template_identify = <<TT;
$template_header
<Identify>
<repositoryName>$setting->{repositoryName}</repositoryName>
<baseURL>[% uri_base %]</baseURL>
<protocolVersion>2.0</protocolVersion>
$admin_email
<earliestDatestamp>[% earliest_datestamp %]</earliestDatestamp>
<deletedRecord>$setting->{deletedRecord}</deletedRecord>
<granularity>$setting->{granularity}</granularity>
<description>
    <oai-identifier xmlns="http://www.openarchives.org/OAI/2.0/oai-identifier"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai-identifier http://www.openarchives.org/OAI/2.0/oai-identifier.xsd">
        <scheme>oai</scheme>
        <repositoryIdentifier>$setting->{repositoryIdentifier}</repositoryIdentifier>
        <delimiter>$setting->{delimiter}</delimiter>
        <sampleIdentifier>$setting->{sampleIdentifier}</sampleIdentifier>
    </oai-identifier>
</description>
@identify_extra_fields
$branding
</Identify>
$template_footer
TT

    my $template_list_identifiers = <<TT;
$template_header
<ListIdentifiers>
[%- FOREACH records %]
$template_record_header
[%- END %]
[%- IF token %]
<resumptionToken cursor="[% start %]" completeListSize="[% total %]">[% token %]</resumptionToken>
[%- ELSE %]
<resumptionToken cursor="[% start %]" completeListSize="[% total %]"/>
[%- END %]
</ListIdentifiers>
$template_footer
TT

    my $template_list_records = <<TT;
$template_header
<ListRecords>
[%- FOREACH records %]
<record>
$template_record_header
[%- UNLESS deleted %]
<metadata>
[% metadata %]
</metadata>
[%- END %]
</record>
[%- END %]
[%- IF token %]
<resumptionToken cursor="[% start %]" completeListSize="[% total %]">[% token %]</resumptionToken>
[%- ELSE %]
<resumptionToken cursor="[% start %]" completeListSize="[% total %]"/>
[%- END %]
</ListRecords>
$template_footer
TT

    my $template_list_metadata_formats = "";
    $template_list_metadata_formats .= <<TT;
$template_header
<ListMetadataFormats>
TT
    for my $format (values %$metadata_formats) {
        $template_list_metadata_formats .= <<TT;
<metadataFormat>
    <metadataPrefix>$format->{metadataPrefix}</metadataPrefix>
    <schema>$format->{schema}</schema>
    <metadataNamespace>$format->{metadataNamespace}</metadataNamespace>
</metadataFormat>
TT
    }
    $template_list_metadata_formats .= <<TT;
</ListMetadataFormats>
$template_footer
TT

    my $template_list_sets = <<TT;
$template_header
<ListSets>
TT
    for my $set (values %$sets) {
        $template_list_sets .= <<TT;
<set>
    <setSpec>$set->{setSpec}</setSpec>
    <setName>$set->{setName}</setName>
TT

    my $set_descriptions = $set->{setDescription} // [];
    $set_descriptions = [$set_descriptions] unless is_array_ref($set_descriptions);
    $template_list_sets .= "<setDescription>$_</setDescription>" for @$set_descriptions;

    $template_list_sets .= <<TT;
</set>
TT
    }
    $template_list_sets .= <<TT;
</ListSets>
$template_footer
TT

    my $fix = $opts{fix} || $setting->{fix};
    if ($fix) {
        $fix = Catmandu::Fix->new(fixes => $fix);
    }
    my $sub_deleted = $opts{deleted} || sub { 0 };
    my $sub_set_specs_for = $opts{set_specs_for} || sub { [] };

    my $template_options = $setting->{template_options} || {};

    my $render = sub {
        my ($tmpl, $data) = @_;
        content_type 'xml';
        my $out = "";
        my $exporter = Catmandu::Exporter::Template->new(template => $tmpl, file => \$out);
        $exporter->add($data);
        $exporter->commit;
        $out;
    };

    any ['get', 'post'] => $path => sub {
        my $uri_base = $setting->{uri_base} // request->uri_for(request->path_info);
        my $response_date = DateTime->now->iso8601.'Z';
        my $params = request->is_get ? params('query') : params('body');
        my $errors = [];
        my $format;
        my $set;
        my $verb = $params->{verb};
        my $vars = {
            uri_base => $uri_base,
            request_uri => $uri_base . $path,
            response_date => $response_date,
            errors => $errors,
        };

        if ($verb and my $spec = $VERBS->{$verb}) {
            my $valid = $spec->{valid};
            my $required = $spec->{required};

            if ($valid->{resumptionToken} and exists $params->{resumptionToken}) {
                if (keys(%$params) > 2) {
                    push @$errors, [badArgument => "resumptionToken cannot be combined with other parameters"];
                }
            } else {
                for my $key (keys %$params) {
                    next if $key eq 'verb';
                    unless ($valid->{$key}) {
                        push @$errors, [badArgument => "parameter $key is illegal"];
                    }
                }
                for my $key (@$required) {
                    unless (exists $params->{$key}) {
                        push @$errors, [badArgument => "parameter $key is missing"];
                    }
                }
            }
        } else {
            push @$errors, [badVerb => "illegal OAI verb"];
        }

        if (@$errors) {
            return $render->(\$template_error, $vars);
        }

        $vars->{params} = $params;

        if ($params->{resumptionToken}) {
            unless (is_string($params->{resumptionToken})) {
                push @$errors, [badResumptionToken => "resumptionToken is not in the correct format"];
            }

            if ($verb eq 'ListSets') {
                push @$errors, [badResumptionToken => "resumptionToken isn't necessary"];
            } else {
                my @parts = split '!', $params->{resumptionToken};

                unless (@parts == 5) {
                    push @$errors, [badResumptionToken => "resumptionToken is not in the correct format"];
                }

                $params->{set}            = $parts[0];
                $params->{from}           = $parts[1];
                $params->{until}          = $parts[2];
                $params->{metadataPrefix} = $parts[3];
                $vars->{start}            = $parts[4];
            }
        }

        if ($params->{set}) {
            unless ($sets) {
                push @$errors, [noSetHierarchy => "sets are not supported"];
            }
            unless ($set = $sets->{$params->{set}}) {
                push @$errors, [badArgument => "set does not exist"];
            }
        }

        if (my $prefix = $params->{metadataPrefix}) {
            unless ($format = $metadata_formats->{$prefix}) {
                push @$errors, [cannotDisseminateFormat => "metadataPrefix $prefix is not supported"];
            }
        }

        if (@$errors) {
            return $render->(\$template_error, $vars);
        }


        if ($verb eq 'GetRecord') {
            my $id = $params->{identifier};
            $id =~ s/^$ns//;

            my $rec = $bag->search(
                %{ $setting->{default_search_params} },
                cql_query => sprintf($setting->{get_record_cql_pattern}, $id),
                start     => 0,
                limit     => 1,
            )->first;

            if (defined $rec) {
                if ($fix) {
                    $rec = $fix->fix($rec);
                }

                $vars->{id} = $id;
                $vars->{datestamp} = $format_datestamp->($rec->{$setting->{datestamp_field}});
                $vars->{deleted} = $sub_deleted->($rec);
                $vars->{setSpec} = $sub_set_specs_for->($rec);
                my $metadata = "";
                my $exporter = Catmandu::Exporter::Template->new(
                    %$template_options,
                    template => $format->{template},
                    file => \$metadata,
                );
                if ($format->{fix}) {
                    $rec = $format->{fix}->fix($rec);
                }
                $exporter->add($rec);
                $exporter->commit;
                $vars->{metadata} = $metadata;
                unless ($vars->{deleted} and $setting->{deletedRecord} eq 'no') {
                    return $render->(\$template_get_record, $vars);
                }
            }
            push @$errors, [idDoesNotExist => "identifier $params->{identifier} is unknown or illegal"];
            return $render->(\$template_error, $vars);

        } elsif ($verb eq 'Identify') {
            $vars->{earliest_datestamp} = $setting->{earliestDatestamp} || do {
                my $hits = $bag->search(
                    %{ $setting->{default_search_params} },
                    cql_query    => $setting->{cql_filter} || 'cql.allRecords',
                    limit        => 1,
                    sru_sortkeys => $setting->{datestamp_field},
                );
                if (my $rec = $hits->first) {
                    $format_datestamp->($rec->{$setting->{datestamp_field}});
                } else {
                    '1970-01-01T00:00:01Z';
                }
            };
            return $render->(\$template_identify, $vars);

        } elsif ($verb eq 'ListIdentifiers' || $verb eq 'ListRecords') {
            my $limit = $setting->{limit} // $DEFAULT_LIMIT;
            my $start = $vars->{start} //= 0;
            my $from  = $params->{from};
            my $until = $params->{until};

            for my $datestamp (($from, $until)) {
                $datestamp || next;
                if ($datestamp !~ /^\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}:\d{2}Z)?$/) {
                    push @$errors, [badArgument => "datestamps must have the format YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ"];
                    return $render->(\$template_error, $vars);
                };
            }

            if ($from && $until && length($from) != length($until)) {
                push @$errors, [badArgument => "datestamps must have the same granularity"];
                return $render->(\$template_error, $vars);
            }

            if ($from && $until && $from gt $until) {
                push @$errors, [badArgument => "from is more recent than until"];
                return $render->(\$template_error, $vars);
            }

            if ($from && length($from) == 10) {
                $from = "${from}T00:00:00Z";
            }
            if ($until && length($until) == 10) {
                $until = "${until}T23:59:59Z";
            }

            my @cql;
            my $cql_from  = $from;
            my $cql_until = $until;
            if (my $pattern = $setting->{datestamp_pattern}) {
                $cql_from = DateTime::Format::ISO8601->parse_datetime($from)->strftime($pattern) if $cql_from;
                $cql_until = DateTime::Format::ISO8601->parse_datetime($until)->strftime($pattern) if $cql_until;
            }

            push @cql, qq|($setting->{cql_filter})| if $setting->{cql_filter};
            push @cql, qq|($format->{cql})| if $format->{cql};
            push @cql, qq|($set->{cql})| if $set && $set->{cql};
            push @cql, qq|($setting->{datestamp_field} >= "$cql_from")| if $cql_from;
            push @cql, qq|($setting->{datestamp_field} <= "$cql_until")| if $cql_until;
            unless (@cql) {
                push @cql, "(cql.allRecords)";
            }

            my $search = $bag->search(
                %{ $setting->{default_search_params} },
                cql_query => join(' and ', @cql),
                limit     => $limit,
                start     => $start,
            );

            unless ($search->total) {
                push @$errors, [noRecordsMatch => "no records found"];
                return $render->(\$template_error, $vars);
            }

            if ($start + $limit < $search->total) {
                $vars->{token} = join '!',
                    $params->{set} || '',
                    $from ? $from : '',
                    $until ? $until : '',
                    $params->{metadataPrefix},
                    $start + $limit;
            }

            $vars->{total} = $search->total;

            if ($verb eq 'ListIdentifiers') {
                $vars->{records} = [map {
                    my $rec = $_;
                    my $id  = $rec->{$bag->id_key};

                    if ($fix) {
                        $rec = $fix->fix($rec);
                    }

                    {
                        id        => $id,
                        datestamp => $format_datestamp->($rec->{$setting->{datestamp_field}}),
                        deleted   => $sub_deleted->($rec),
                        setSpec   => $sub_set_specs_for->($rec),
                    };
                } @{$search->hits}];
                return $render->(\$template_list_identifiers, $vars);
            } else {
                $vars->{records} = [map {
                    my $rec = $_;
                    my $id  = $rec->{$bag->id_key};

                    if ($fix) {
                        $rec = $fix->fix($rec);
                    }

                    my $deleted = $sub_deleted->($rec);

                    my $rec_vars = {
                        id        => $id,
                        datestamp => $format_datestamp->($rec->{$setting->{datestamp_field}}),
                        deleted   => $deleted,
                        setSpec   => $sub_set_specs_for->($rec),
                    };
                    unless ($deleted) {
                        my $metadata = "";
                        my $exporter = Catmandu::Exporter::Template->new(
                            %$template_options,
                            template => $format->{template},
                            file     => \$metadata,
                        );
                        if ($format->{fix}) {
                            $rec = $format->{fix}->fix($rec);
                        }
                        $exporter->add($rec);
                        $exporter->commit;
                        $rec_vars->{metadata} = $metadata;
                    }
                    $rec_vars;
                } @{$search->hits}];
                return $render->(\$template_list_records, $vars);
            }

        } elsif ($verb eq 'ListMetadataFormats') {
            if (my $id = $params->{identifier}) {
                $id =~ s/^$ns//;
                unless ($bag->get($id)) {
                    push @$errors, [idDoesNotExist => "identifier $params->{identifier} is unknown or illegal"];
                    return $render->(\$template_error, $vars);
                }
            }
            return $render->(\$template_list_metadata_formats, $vars);

        } elsif ($verb eq 'ListSets') {
            return $render->(\$template_list_sets, $vars);
        }
    }
};

register oai_provider => \&oai_provider;

register_plugin;

1;

=head1 SYNOPSIS

    #!/usr/bin/env perl

    use Dancer;
    use Catmandu;
    use Dancer::Plugin::Catmandu::OAI;

    Catmandu->load;
    Catmandu->config;

    my $options = {};

    oai_provider '/oai' , %$options;

    dance;

=head1 DESCRIPTION

L<Dancer::Plugin::Catmandu::OAI> is a Dancer plugin to provide OAI-PMH services for L<Catmandu::Store>-s that support
CQL (such as L<Catmandu::Store::ElasticSearch>). Follow the installation steps below to setup your own OAI-PMH server.

=head1 REQUIREMENTS

In the examples below an ElasticSearch 1.7.2 L<https://www.elastic.co/downloads/past-releases/elasticsearch-1-7-2> server
will be used.

Follow the instructions below for a demonstration installation:

    $ cpanm Dancer Catmandu::OAI Catmandu::Store::ElasticSearch

    $ wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.2.zip
    $ unzip elasticsearch-1.7.2.zip
    $ cd elasticsearch-1.7.2
    $ bin/elasticsearch

=head1 RECORDS

Records stored in the Catmandu::Store can be in any format. Preferably the format should be easy to convert into the
mandatory OAI-DC format. At a minimum each record contains an identifier '_id' and a field containing a datestamp.

    $ cat sample.yml
    ---
    _id: oai:my.server.org:123456
    datestamp: 2016-05-17T13:37:18Z
    creator:
     - Musterman, Max
     - Jansen, Jan
     - Svenson, Sven
    title:
     - Test record
    ...

=head1 CATMANDU CONFIGURATION

ElasticSearch requires a configuration file to map record fields to CQL terms. Below is a minimal configuration required to query
for identifiers and datastamps in the ElasticSearch collection:

    $ cat catmandu.yml
    ---
    store:
      oai:
        package: ElasticSearch
        options:
          index_name: oai
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
                  datestamp:
                    op:
                      '=': true
                      '<': true
                      '<=': true
                      '>=': true
                      '>': true
                      'exact': true
                    field: 'datestamp'
          index_mappings:
            publication:
              properties:
                datestamp: {type: date, format: date_time_no_millis}

=head1 IMPORT RECORDS

With the Catmandu configuration files in place records can be imported with the L<catmandu> command:

    # Drop the existing ElasticSearch 'oai' collection
    $ catmandu drop oai

    # Import the sample record
    $ catmandu import YAML to oai < sample.yml

    # Test if the records are available in the 'oai' collection
    $ catmandu export oai

=head1 DANCER CONFIGURATION

The Dancer configuration file 'config.yml' contains basic information for the OAI-PMH plugin to work:

    * store - In which Catmandu::Store are the metadata records stored
    * bag - In which Catmandu::Bag are the records of this 'store' (use: 'data' as default)
    * datestamp_field - Which field in the record contains a datestamp ('datestamp' in our example above)
    * repositoryName - The name of the repository
    * uri_base - The full base url of the OAI controller. To be used when behind a proxy server. When not set, this module relies on the Dancer request to provide its full url. Use middleware like 'ReverseProxy' or 'Dancer::Middleware::Rebase' in that case.
    * adminEmail - An administrative email. Can be string or array of strings. This will be included in the Identify response.
    * compression - a compression encoding supported by the repository. Can be string or array of strings. This will be included in the Identify response.
    * description - XML container that describes your repository. Can be string or array of strings. This will be included in the Identify response. Note that this module will try to validate the XML data.
    * earliestDatestamp - The earliest datestamp available in the dataset as YYYY-MM-DDTHH:MM:SSZ. This will be determined dynamically if no static value is given.
    * deletedRecord - The policy for deleted records. See also: L<https://www.openarchives.org/OAI/openarchivesprotocol.html#DeletedRecords>
    * repositoryIdentifier - A prefix to use in OAI-PMH identifiers
    * cql_filter -  A CQL query to find all records in the database that should be made available to OAI-PMH
    * limit - The maximum number of records to be returned in each OAI-PMH request
    * delimiter - Delimiters used in prefixing a record identifier with a repositoryIdentifier (use: ':' as default)
    * sampleIdentifier - A sample identifier
    * metadata_formats - An array of metadataFormats that are supported
        * metadataPrefix - A short string for the name of the format
        * schema - An URL to the XSD schema of this format
        * metadataNamespace - A XML namespace for this format
        * template - The path to a Template Toolkit file to transform your records into this format
        * fix - Optionally an array of one or more L<Catmandu::Fix>-es or Fix files
    * sets - Optional an array of OAI-PMH sets and the CQL query to retrieve records in this set from the Catmandu::Store
        * setSpec - A short string for the same of the set
        * setName - A longer description of the set
        * setDescription - an optional and repeatable container that may hold community-specific XML-encoded data about the set. Should be string or array of strings.
        * cql - The CQL command to find records in this set in the L<Catmandu::Store>
    * xsl_stylesheet - Optional path to an xsl stylesheet
    * template_options - An optional hash of configuration options that will be passed to L<Catmandu::Exporter::Template> or L<Template>.

Below is a sample minimal configuration for the 'sample.yml' demo above:

    $ cat config.yml
    charset: "UTF-8"
    plugins:
      'Catmandu::OAI':
        store: oai
        bag: data
        datestamp_field: datestamp
        repositoryName: "My OAI DataProvider"
        uri_base: "http://oai.service.com/oai"
        adminEmail: me@example.com
        earliestDatestamp: "1970-01-01T00:00:01Z"
        cql_filter: "datestamp>1970-01-01T00:00:01Z"
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
            template: oai_dc.tt

=head1 METADATAPREFIX TEMPLATE

For each metadataPrefix a Template Toolkit file needs to exist which translate L<Catmandu::Store> records into XML records. At least
one Template Toolkit file should be made available to transform stored records into Dublin Core. The example below contains an example file to
transform 'sample.yml' type records into Dublin Core:

    $ cat oai_dc.tt
    <oai_dc:dc xmlns="http://www.openarchives.org/OAI/2.0/oai_dc/"
               xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
               xmlns:dc="http://purl.org/dc/elements/1.1/"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
    [%- FOREACH var IN ['title' 'creator' 'subject' 'description' 'publisher' 'contributor' 'date' 'type' 'format' 'identifier' 'source' 'language' 'relation' 'coverage' 'rights'] %]
        [%- FOREACH val IN $var %]
        <dc:[% var %]>[% val | html %]</dc:[% var %]>
        [%- END %]
    [%- END %]
    </oai_dc:dc>

=head1 START DANCER

If all the required files are available, then a Dancer application can be started. See the 'demo' directory of this distribution for a complete example:

    $ ls
    app.pl  catmandu.yml  config.yml  oai_dc.tt
    $ cat app.pl
    #!/usr/bin/env perl

    use Dancer;
    use Catmandu;
    use Dancer::Plugin::Catmandu::OAI;

    Catmandu->load;
    Catmandu->config;

    my $options = {};

    oai_provider '/oai' , %$options;

    dance;

    # Start Dancer
    $ perl ./app.pl

    # Test queries:

    $ curl "http://localhost:3000/oai?verb=Identify"
    $ curl "http://localhost:3000/oai?verb=ListSets"
    $ curl "http://localhost:3000/oai?verb=ListMetadataFormats"
    $ curl "http://localhost:3000/oai?verb=ListIdentifiers&metadataPrefix=oai_dc"
    $ curl "http://localhost:3000/oai?verb=ListRecords&metadataPrefix=oai_dc"

=head1 SEE ALSO

L<Dancer>, L<Catmandu>, L<Catmandu::Store>

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 CONTRIBUTORS

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

Vitali Peil, C<< <vitali.peil at uni-bielefeld.de> >>

Patrick Hochstenbach, C<< <patric.hochstenbach at ugent.be> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
