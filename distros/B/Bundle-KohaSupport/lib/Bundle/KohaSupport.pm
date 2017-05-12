package Bundle::KohaSupport;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.31';

1;
__END__


=head1 NAME

Bundle::KohaSupport - A bundle of the required Perl modules for Koha Intergrated Library System

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::KohaSupport'>

=head1 DESCRIPTION

This bundle gathers together and installs all of the prerequisite 
Perl modules for Koha, the open source integrated library system.

=head1 CONTENTS

Algorithm::CheckDigits 0.50
Biblio::EndnoteStyle 0.05
CGI 3.15
CGI::Carp 1.29
CGI::Session 4.10
Class::Factory::Util 1.6
Class::Accessor 0.30
DBD::mysql 4.004
DBI 1.53
Data::ICal 0.13
Data::Dumper 2.121
Date::Calc 5.4
Date::ICal 1.72
Date::Manip 5.44
Digest::MD5 2.36
File::Temp 0.16
GD::Barcode::UPCE 1.1
Getopt::Long 2.35
Getopt::Std 1.05
HTML::Template::Pro 0.69
HTML::Scrubber 0.08
HTTP::Cookies 1.39
HTTP::Request::Common 1.26
Image::Magick 6.2
LWP::Simple 1.41
LWP::UserAgent 2.033
Lingua::Stem 0.82
List::Util 1.18
List::MoreUtils 0.21
Locale::Language 2.07
MARC::Charset 0.98
MARC::Crosswalk::DublinCore 0.02
MARC::File::XML 0.88
MARC::Record 2.00
MIME::Base64 3.07
MIME::Lite 3.00
MIME::QuotedPrint 3.07
Mail::Sendmail 0.79
Net::LDAP 0.33
Net::LDAP::Filter 0.14
Net::Z3950::ZOOM 1.16
PDF::API2 2.000
PDF::API2::Page 2.000
PDF::API2::Util 2.000
PDF::Reuse 0.33
PDF::Reuse::Barcode 0.05
POE 0.9999
POSIX 1.09
Schedule::At 1.06
SMS::Send 0.05
Term::ANSIColor 1.10
Test 1.25
Test::Harness 2.56
Test::More 0.62
Text::CSV 0.01
Text::CSV_XS 0.32
Text::Iconv 1.7
Text::Wrap 2005.082401
Time::HiRes 1.86
Time::localtime 1.02
Unicode::Normalize 0.32
XML::Dumper 0.81
XML::LibXML 1.59
XML::LibXSLT 1.59
XML::SAX::ParserFactory 1.01
XML::Simple 2.14
XML::RSS 1.31
YAML::Syck 0.71

=head1 SEE ALSO

To find more information on Koha or its requirements, visit 
L<http://www.koha.org/>.

=head1 AUTHOR

Mike Mylonas, <koha@dragon-is.co.nz>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Mike Mylonas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
