package Catmandu::Importer::WoSRetrieveById;

use Catmandu::Sane;

our $VERSION = '0.0303';

use Moo;
use Catmandu::Util qw(is_value xml_escape);
use namespace::clean;

with 'Catmandu::WoS::SearchRecords';

has uid => (
    is       => 'ro',
    required => 1,
    coerce   => sub {is_value($_[0]) ? [split ',', $_[0]] : $_[0]}
);

sub _search_content {
    my ($self, $start, $limit) = @_;

    my $uid = join '',
        map {'<uid>' . xml_escape($_) . '</uid>'} @{$self->uid};

    <<EOF;
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
   xmlns:woksearch="http://woksearch.v3.wokmws.thomsonreuters.com">
   <soapenv:Header/>
   <soapenv:Body>
      <woksearch:retrieveById>
         <databaseId>WOS</databaseId>
         $uid
         <queryLanguage>en</queryLanguage>
         <retrieveParameters>
            <firstRecord>$start</firstRecord>
            <count>$limit</count>
            <option>
               <key>RecordIDs</key>
               <value>On</value>
            </option>
         </retrieveParameters>
      </woksearch:retrieveById>
   </soapenv:Body>
</soapenv:Envelope>
EOF
}

sub _search_response_type {
    'retrieveByIdResponse';
}

1;

__END__

=encoding utf-8

=head1 NAME

Catmandu::Importer::WoSRetrieveById - Import Web of Science records by id

=head1 SYNOPSIS

    # On the command line

    $ catmandu convert WoSRetrieveById --username XXX --password XXX --uid 'WOS:000413520000001' to YAML

    # In perl

    use Catmandu::Importer::WoSRetrieveById;
    
    my $wos = Catmandu::Importer::WoSRetrieveById->new(username => 'XXX', password => 'XXX', uid => ['WOS:000413520000001']);
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
