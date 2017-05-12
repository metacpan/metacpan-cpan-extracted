# $Id: ScanDetails.pm 18 2008-05-05 23:55:18Z jabra $
package Burpsuite::Parser::ScanDetails;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use XML::LibXML;
    use Burpsuite::Parser::Issue;

    my @issues : Field : Arg(issues) : Get(issues) : Type( List(Burpsuite::Parser::Issue) );

    sub parse {
        my ( $self, $parser, $doc ) = @_;

        my $xpc = XML::LibXML::XPathContext->new($doc);
        my @issues;
        foreach my $h ( $xpc->findnodes('//issues/issue') ) {
            my $confidence
                    = @{$h->getElementsByTagName('confidence')}[0]->textContent();
            my $serial_number
                    = @{$h->getElementsByTagName('serialNumber')}[0]->textContent();
            my $type
                    = @{$h->getElementsByTagName('type')}[0]->textContent();
            my $name
            = @{$h->getElementsByTagName('name')}[0]->textContent();
            my $host
                    = @{$h->getElementsByTagName('host')}[0]->textContent();
            my $path
                    = @{$h->getElementsByTagName('path')}[0]->textContent();
            my $location
                    = @{$h->getElementsByTagName('location')}[0]->textContent();
            my $severity
                    = @{$h->getElementsByTagName('severity')}[0]->textContent();


            my $issue_background = 
                scalar( @{$h->getElementsByTagName('issueBackground')} ) > 0 
                ? @{$h->getElementsByTagName('issueBackground')}[0]->textContent()
                : '';
            
            my $remediation_background = 
                scalar( @{$h->getElementsByTagName('remediationBackground')} ) > 0 
                ? @{$h->getElementsByTagName('remediationBackground')}[0]->textContent() 
                : '';

            my $issue_detail = 
                scalar( @{$h->getElementsByTagName('issueDetail')} ) > 0 
                ? @{$h->getElementsByTagName('issueDetail')}[0]->textContent()
                : '';
        
            my $issue = Burpsuite::Parser::Issue->new(
                serial_number => $serial_number,
                type => $type,
                name => $name,
                host => $host,
                path => $path,
                location => $location,
                severity => $severity,
                confidence => $confidence,
                issue_background => $issue_background,
                issue_detail => $issue_detail,
                remediation_background => $remediation_background, 
                request => '',
                response => '',
                );

            push( @issues, $issue );
        }
        
        return Burpsuite::Parser::ScanDetails->new( issues => \@issues );
    }

    sub all_issues {
        my ($self) = @_;
        my @issues = @{ $self->issues };
        return @issues;
    }
}
1;
