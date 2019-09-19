package Catmandu::Importer::WoSCitedReferences;

use Catmandu::Sane;

our $VERSION = '0.0302';

use Moo;
use Catmandu::Util qw(is_string xml_escape);
use namespace::clean;

with 'Catmandu::WoS::SearchBase';

has uid => (is => 'ro', required => 1);

sub _search_content {
    my ($self, $start, $limit) = @_;

    my $uid = xml_escape($self->uid);

    <<EOF;
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
   xmlns:woksearch="http://woksearch.v3.wokmws.thomsonreuters.com">
   <soapenv:Header/>
   <soapenv:Body>
      <woksearch:citedReferences>
         <databaseId>WOS</databaseId>
         <uid>$uid</uid>
         <queryLanguage>en</queryLanguage>
         <retrieveParameters>
            <firstRecord>$start</firstRecord>
            <count>$limit</count>
            <option>
              <key>Hot</key>
              <value>On</value>
            </option>
         </retrieveParameters>
      </woksearch:citedReferences>
   </soapenv:Body>
</soapenv:Envelope>
EOF
}

sub _retrieve_content {
    my ($self, $query_id, $start, $limit) = @_;

    $query_id = xml_escape($query_id);

    <<EOF;
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
   <soap:Header/>
   <soap:Body>
      <woksearch:citedReferencesRetrieve xmlns:woksearch="http://woksearch.v3.wokmws.thomsonreuters.com">
         <queryId>$query_id</queryId>
         <retrieveParameters>
            <firstRecord>$start</firstRecord>
            <count>$limit</count>
         </retrieveParameters>
      </woksearch:citedReferencesRetrieve>
   </soap:Body>
</soap:Envelope>
EOF
}

sub _search_response_type {
    'citedReferencesResponse';
}

sub _retrieve_response_type {
    'citedReferencesRetrieveResponse';
}

sub _find_records {
    my ($self, $xpc, $response_type) = @_;
    my @nodes = $xpc->findnodes(
        "/soap:Envelope/soap:Body/ns2:$response_type/return/references");
    [
        map {
            my $node = $_;
            my $ref  = {};
            for my $key (
                qw(uid docid articleId citedAuthor timesCited year page volume citedTitle citedWork hot)
                )
            {
                my $val = $node->findvalue($key);
                $ref->{$key} = $val if is_string($val);
            }
            $ref;
        } @nodes
    ];
}

1;

1;

__END__

=encoding utf-8

=head1 NAME

Catmandu::Importer::WoSCitedReferences - Import Web of Science cited references for a given record

=head1 SYNOPSIS

    # On the command line

    $ catmandu convert WoSCitedReferences --username XXX --password XXX --uid 'WOS:000413520000001' to YAML

    # In perl

    use Catmandu::Importer::WoS;
    
    my $wos = Catmandu::Importer::WoSCitedReferences->new(username => 'XXX', password => 'XXX', uid => 'WOS:000413520000001');
    $wos->each(sub {
        my $cite = shift;
        # ...
    });

=head1 AUTHOR

Nicolas Steenlant E<lt>nicolas.steenlant@ugent.beE<gt>

=head1 COPYRIGHT

Copyright 2017- Nicolas Steenlant

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
