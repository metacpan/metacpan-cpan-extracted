package Catmandu::Importer::SRU::Parser::ppxml;

our $VERSION = '1.09';

use Moo;
use PICA::Parser::PPXML;

sub parse {
    my ( $self, $record ) = @_;

    my $xml    = $record->{recordData}->toString();
    my $parser = PICA::Parser::PPXML->new($xml);

    my $next = $parser->next;
    return $next ? {%$next} : undef;
}

1;
__END__

=head1 NAME

Catmandu::Importer::SRU::Parser::ppxml - Parse SRU response with PICA+ XML data (PPXML, a format variant of the Deutsche Nationalbibliothek) into Catmandu PICA

=head1 SYNOPSIS

    my %attrs = (
        base => 'http://services.dnb.de/sru/zdb',
        query => 'zdbid = 24220127',
        recordSchema => 'PicaPlus-xml' ,
        parser => 'ppxml' ,
    );

    my $importer = Catmandu::Importer::SRU->new(%attrs);

To give an example for use of the L<catmandu> command line client:

    catmandu convert SRU --base http://services.dnb.de/sru/zdb
                         --query "zdbid = 24220127" 
                         --recordSchema PicaPlus-xml
                         --parser ppxml 
                     to PICA --type plain

=head1 DESCRIPTION

Each ppxml response will be transformed into the format defined by
L<Catmandu::Importer::PICA>

=cut
