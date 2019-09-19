package Catmandu::Importer::WoS;

use Catmandu::Sane;

our $VERSION = '0.0302';

use Moo;
use Catmandu::Util qw(xml_escape);
use namespace::clean;

with 'Catmandu::WoS::SearchRecords';

has query             => (is => 'ro', required => 1);
has symbolic_timespan => (is => 'ro');
has timespan_begin    => (is => 'ro');
has timespan_end      => (is => 'ro');

sub _search_content {
    my ($self, $start, $limit) = @_;

    my $query = xml_escape($self->query);

    my $symbolic_timespan_xml = '';
    my $timespan_xml          = '';

    if (my $ts = $self->symbolic_timespan) {
        $symbolic_timespan_xml = "<symbolicTimeSpan>$ts</symbolicTimeSpan>";
    }
    elsif ($self->timespan_begin && $self->timespan_end) {
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
      <woksearch:search>
         <queryParameters>
            <databaseId>WOS</databaseId>
            <userQuery>$query</userQuery>
            $symbolic_timespan_xml
            $timespan_xml
            <queryLanguage>en</queryLanguage>
         </queryParameters>
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
      </woksearch:search>
   </soapenv:Body>
</soapenv:Envelope>
EOF
}

sub _search_response_type {
    'searchResponse';
}

1;

__END__

=encoding utf-8

=head1 NAME

Catmandu::Importer::WoS - Import Web of Science records

=head1 SYNOPSIS

    # On the command line

    $ catmandu convert WoS --username XXX --password XXX --query 'TS=(lead OR cadmium)' to YAML

    # In perl

    use Catmandu::Importer::WoS;
    
    my $wos = Catmandu::Importer::WoS->new(username => 'XXX', password => 'XXX', query => 'TS=(lead OR cadmium)');
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
