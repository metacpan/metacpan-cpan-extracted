package Catmandu::Importer::WoSRelatedRecords;

use Catmandu::Sane;

our $VERSION = '0.0302';

use Moo;
use Catmandu::Util qw(xml_escape);
use namespace::clean;

with 'Catmandu::WoS::SearchRecords';

has uid            => (is => 'ro', required => 1);
has timespan_begin => (is => 'ro');
has timespan_end   => (is => 'ro');

sub _search_content {
    my ($self, $start, $limit) = @_;

    my $uid = xml_escape($self->uid);

    my $timespan_xml = '';
    if ($self->timespan_begin && $self->timespan_end) {
        my $tsb = $self->timespan_begin;
        my $tse = $self->timespan_end;
        $timespan_xml
            = "<timeSpan><begin>$tsb</begin><end>$tse</end></timeSpan>";
    }

    <<EOF;
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
   xmlns:woksearch="http://woksearch.v3.wokmws.thomsonreuters.com">
   <soapenv:Header/>
   <soapenv:Body>
      <woksearch:relatedRecords>
         <databaseId>WOS</databaseId>
         <uid>$uid</uid>
         $timespan_xml
         <queryLanguage>en</queryLanguage>
         <retrieveParameters>
            <firstRecord>$start</firstRecord>
            <count>$limit</count>
            <option>
               <key>RecordIDs</key>
               <value>On</value>
            </option>
            <option>
               <key>targetNamespace</key>
               <value>http://scientific.thomsonreuters.com/schema/wok5.4/public/FullRecord</value>
            </option>
        </retrieveParameters>
      </woksearch:relatedRecords>
   </soapenv:Body>
</soapenv:Envelope>
EOF
}

sub _search_response_type {
    'relatedRecordsResponse';
}

1;

__END__

=encoding utf-8

=head1 NAME

Catmandu::Importer::WoSRelatedRecords - Import Web of Science related records for a given record

=head1 SYNOPSIS

    # On the command line

    $ catmandu convert WoSRelatedRecords --username XXX --password XXX --uid 'WOS:000413520000001' to YAML

    # In perl

    use Catmandu::Importer::WoSRelatedRecords;
    
    my $wos = Catmandu::Importer::WoSRelatedRecords->new(username => 'XXX', password => 'XXX', uid => 'WOS:000413520000001');
    $wos->each(sub {
        my $record = shift;
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
