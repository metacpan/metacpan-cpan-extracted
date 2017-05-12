# $Id: Parser.pm 71 2008-08-31 05:58:17Z jabra $
package Burpsuite::Parser;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use Burpsuite::Parser::Session;
    my @session : Field : Arg(session) : Get(session) : Type(Burpsuite::Parser::Session);

    # parse_file
    #
    # Input:
    # argument  -   self obj    -
    # argument  -   xml         scalar
    #
    # Ouptut:
    #
    sub parse_file {
        my ( $self, $file ) = @_;
        my $parser = XML::LibXML->new();

        my $doc = $parser->parse_file($file);
        return Burpsuite::Parser->new(
            session => Burpsuite::Parser::Session->parse( $parser, $doc ) );
    }

    sub get_session {
        my ($self) = @_;
        return $self->session;
    }   

    sub get_all_issues {
        my ($self) = @_;
        my @all_issues = $self->session->scandetails->all_issues();
        return @all_issues;
    }
}
1;

