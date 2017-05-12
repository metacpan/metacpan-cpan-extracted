# In order to simulate the behaviour, I'll re-write the methods of
# XML::Compile::SOAP::WSDL11, returning a known structure so that we
# can predict the answer and also avoid centering the test on
# XML::Compile::SOAP and depending on network.
{
    package XML::Compile::WSDL11;
    use Symbol;
    sub new {
        return bless { symbol => gensym() }, MyXML::WSDL11;
    }
};
{
    package MyXML::WSDL11;
    sub operations {
        return
          (
           (bless { name => 'op1', service => 'sv1', port => 'pt1' }, MyXML::Operation),
           (bless { name => 'op2', service => 'sv1', port => 'pt1' }, MyXML::Operation),
           (bless { name => 'op3', service => 'sv1', port => 'pt2' }, MyXML::Operation),
           (bless { name => 'op4', service => 'sv2', port => 'pt3' }, MyXML::Operation),
           (bless { name => 'op5', service => 'sv2', port => 'pt4' }, MyXML::Operation),
          )
    }
    sub importDefinitions {
    }
};
{
    package MyXML::Operation;
    sub compileClient {
        my $self = shift;
        return sub { return $self->{name} };
    }
    sub port {
        my $self = shift;
        return $self->{port};
    }
    sub service {
        my $self = shift;
        return $self->{service};
    }
    sub name {
        my $self = shift;
        return $self->{name};
    }
    sub soapStyle {
        'document'
    }
};
1;
