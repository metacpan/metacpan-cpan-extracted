# $Id: Issue.pm 18 2008-05-05 23:55:18Z jabra $
package Burpsuite::Parser::Issue;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;

    my @serial_number : Field : Arg(serial_number) : Get(serial_number);
    my @name : Field : Arg(name) : Get(name);
    my @host : Field : Arg(host) : Get(host);
    my @path : Field : Arg(path) : Get(path);
    my @location : Field : Arg(location) : Get(location);
    my @severity : Field : Arg(severity) : Get(severity);
    my @confidence : Field : Arg(confidence) : Get(confidence);
    my @issue_background : Field : Arg(issue_background) : Get(issue_background);
    my @issue_detail : Field : Arg(issue_detail) : Get(issue_detail);
    my @remediation_background : Field : Arg(remediation_background) : Get(remediation_background);
    my @type : Field : Arg(type) : Get(type);
    my @request : Field : Arg(request) : Get(request);
    my @response : Field : Arg(response) : Get(response);
}
1;
