# $Id: Session.pm 18 2008-05-05 23:55:18Z jabra $
package Burpsuite::Parser::Session;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use XML::LibXML;
    use Burpsuite::Parser::ScanDetails;

    my @export_time : Field : Arg(export_time) : All(export_time);
    my @version : Field : Arg(version) : All(version);
    my @scandetails : Field : Arg(scandetails) : Get(scandetails) :
        Type(Burpsuite::Parser::ScanDetails);

    sub parse {
        my ( $self, $parser, $doc ) = @_;

        foreach my $burpsuite ( $doc->getElementsByTagName('issues') ) {
            return Burpsuite::Parser::Session->new(
                version     => $burpsuite->getAttribute('burpVersion'),
                export_time  => $burpsuite->getAttribute('exportTime'),
                scandetails => Burpsuite::Parser::ScanDetails->parse( $parser, $doc ),
            );
        }
    }
}
1;
