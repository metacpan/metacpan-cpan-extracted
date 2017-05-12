package minimalapp;

# This application is one of the most simple CGI::XMLApplications one
# can write. It simply defines a stylesheet and passes the variable
# "version" to the stylesheetprocessor. 
#
# Since this application makes no use of any events, there are none 
# registred. Even the default event is ommited because it does nothing.

use CGI::XMLApplication;

@minimalapp::ISA = qw( CGI::XMLApplication );

sub getStylesheet {
    return "minimal.xsl"; 
}

sub getXSLParameter {
    return ( version => $CGI::XMLApplication::VERSION );
}

1;
