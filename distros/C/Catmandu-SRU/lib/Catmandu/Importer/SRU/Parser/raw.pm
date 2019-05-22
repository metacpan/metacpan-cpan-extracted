package Catmandu::Importer::SRU::Parser::raw;

use Moo;

our $VERSION = '0.422';

sub parse {
    my ($self, $record) = @_;

    my $xml = $record->{recordData}->toString;
    $record->{recordData} = $xml;

    return $record;
}

1;
__END__

=head1 NAME

Catmandu::Importer::SRU::Parser::raw - Package transforms SRU responses into a Perl hash

=head1 SYNOPSIS

  my $importer = Catmandu::Importer::SRU->new(
    base => 'http://www.unicat.be/sru',
    query => '(isbn=0855275103 or isbn=3110035170 or isbn=9010017362 or isbn=9014026188)',
    recordSchema => 'marcxml',
    parser => 'raw',
  );

=head1 DESCRIPTION

Transforms each SRU record into a Perl hash containing the following fields:

=over

=item recordSchema

the L<SRU record schema|http://www.loc.gov/standards/sru/recordSchemas/>

=item recordPacking

the SRU format (can be 'string' or 'xml')

=item recordPosition 

the result number

=item recordData

the unparsed record payload

=back

=head1 SEE ALSO

L<Catmandu::Importer::SRU::Parser::meta>

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=cut
