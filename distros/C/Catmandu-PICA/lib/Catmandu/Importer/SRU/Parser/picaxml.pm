package Catmandu::Importer::SRU::Parser::picaxml;

our $VERSION = '1.07';

use Moo;
use PICA::Parser::XML;

sub parse {
    my ( $self, $record ) = @_;

    my $xml    = $record->{recordData}->toString();
    my $parser = PICA::Parser::XML->new($xml);

    my $next = $parser->next;
    return $next ? {%$next} : undef;
}

1;
__END__

=head1 NAME

Catmandu::Importer::SRU::Parser::picaxml - Parse SRU response with PICA+ data into Catmandu PICA

=head1 SYNOPSIS

    my %attrs = (
        base => 'http://sru.gbv.de/gvk',
        query => '1940-5758',
        recordSchema => 'picaxml' ,
        parser => 'picaxml' ,
    );

    my $importer = Catmandu::Importer::SRU->new(%attrs);

To give an example for use of the L<catmandu> command line client:

    catmandu convert SRU --base http://sru.gbv.de/gvk 
                         --query "pica.isb=0-937175-64-1" 
                         --recordSchema picaxml 
                         --parser picaxml 
                     to PICA --type plain

=head1 DESCRIPTION

Each picaxml response will be transformed into the format defined by
L<Catmandu::Importer::PICA>

=cut
