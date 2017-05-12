package Bundle::myxCal;

$VERSION = '0.03';

1;

__END__

=head1 NAME

Bundle::myxCal - a CPAN bundle for the myxCal XML/CGI calendaring application

=head1 SYNOPSIS

  perl -MCPAN -e "install 'Bundle::myxCal'"

=head1 CONTENTS

 CGI [ 2.89 ]
 CGI::Cache [ 1.40 ]
 CGI::Session [ 3.94 ]
 CGI::Session::File [ 3.1.4.1 ]
 CGI::Session::ID::MD5 [ 3.2 ]
 CGI::Session::Serialize::Default [ 1.5 ]
 Digest::MD5 [ 2.24 ]
 Digest::SHA1 [ 2.02 ]
 Cache::Cache [ 1.02 ]
 Class::Factory::Util [ 1.4 ]
 DBD::mysql
 DBI 
 Date::Calc [ 5.3 ]
 Test::More 
 Module::Info
 ExtUtils::ParseXS
 Archive::Tar
 YAML
 Module::Build
 DateTime [ 0.10 ]
 DateTime::Format::Builder [ 0.62 ]
 Class::Singleton
 DateTime::TimeZone [ 0.12 ]
 Params::Validate [ 0.58 ]
 DateTime::LeapSecond [ 0.02 ]
 DateTime::Format::ICal [ 0.04 ]
 DateTime::Format::MySQL [ 0.03 ]
 DateTime::TimeZone::Floating [ 0.01 ]
 DateTime::TimeZone::OffsetOnly [ 0.01 ]
 DateTime::TimeZone::UTC [ 0.01 ]
 Error [ 0.15 ]
 HTML::CalendarMonthSimple [ 1.22 ]
 HTML::Entities [ 1.25 ]
 HTML::Parser [ 3.28 ]
 HTML::Scrubber [ 0.02 ]
 HTTP::Status [ 1.26 ]
 LWP::Simple [ 1.36 ]
 Log::Dispatch [ 2.05 ]
 Log::Dispatch::Base [ 1.09 ]
 Log::Dispatch::File [ 1.22 ]
 Log::Dispatch::Output [ 1.26 ]
 XML::SAX
 XML::NamespaceSupport
 XML::SAX::Expat
 XML::LibXML [ 1.53 ]
 XML::LibXML::Common [ 0.12 ]
 XML::LibXSLT [ 1.53 ]
 XML::NamespaceSupport [ 1.08 ]
 XML::Parser [ 2.31 ]
 XML::Parser::Expat [ 2.31 ]
 XML::SAX [ 0.12 ]
 XML::SAX::Base [ 1.04 ]
 XML::SAX::Exception [ 1.01 ]
 XML::SAX::Expat [ 0.35 ]
 XML::SAX::ParserFactory [ 1.01 ]
 XML::Simple [ 2.02 ]

=head2 DESCRIPTION

Bundle::myxCal will install all the perl modules required to run
myxCal, an XML/CGI calendaring application. This bundle was created
using the following procedure:
 
 h2xs -AXcfn Bundle::myxCal

and then editing the .pm file appropriately. Then, from a bash prompt:

 perl -d:Modlist -MDevel::Modlist=nocore [all cgi files] 2>&1 |egrep '^[A-Z].*[0-9]$'|awk '{print $1 " [ " $2 " ]"}'

This output was then moved into the CONTENTS section.

=head1 AUTHOR

Duncan M. McGreggor <oubiwann at cpan dot org>

=head1 SEE ALSO

L<http://www.sf.net/projects/myxcal>.

=cut
