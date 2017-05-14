use strict;
use warnings;

use IO::Extended qw(:all);


my $prereq =
{
	  
# the static prerequisites

'Class::Maker' => '0.05.17',
'Regexp::Box' => '0.01',
'Error' => '0.15',
'IO::Extended' => '0.06',
'Tie::ListKeyedHash' => '0.41',
'Data::Iter' => '0',
'Class::Multimethods' => '1.70',
'Attribute::Util' => '0.01',
'DBI' => '1.30',
'Text::TabularDisplay' => '1.18',
'String::ExpandEscapes' => '0.01',
'XML::LibXSLT' => '1.53',

          
# prerequisites by datatype

'Locale::Language' => '2.21', # STD::LANGCODE, STD::LANGNAME
'Business::CreditCard' => '0.27', # STD::CREDITCARD
'Email::Valid' => '0.15', # STD::EMAIL
'Business::UPC' => '0.04', # STD::UPC
'HTML::Lint' => '1.26', # STD::HTML
'Business::CINS' => '1.13', # STD::CINS
'Date::Parse' => '2.27', # DB::DATE, STD::DATE
'Net::IPv6Addr' => '0.2', # STD::IP
'Business::ISSN' => '0.90', # STD::ISSN
'Regexp::Common' => '2.113', # STD::INT, STD::IP, STD::QUOTED, STD::REAL, STD::URI, STD::ZIP
'X500::DN' => '0.28', # STD::X500::DN
'Locale::SubCountry' => '', # STD::COUNTRYCODE, STD::COUNTRYNAME, STD::REGIONCODE, STD::REGIONNAME
'XML::Schema' => '0.07', # W3C::ANYURI, W3C::BASE64BINARY, W3C::BOOLEAN, W3C::BYTE, W3C::DATE, W3C::DATETIME, W3C::DECIMAL, W3C::DOUBLE, W3C::DURATION, W3C::ENTITIES, W3C::ENTITY, W3C::FLOAT, W3C::GDAY, W3C::GMONTH, W3C::GMONTHDAY, W3C::GYEAR, W3C::GYEARMONTH, W3C::HEXBINARY, W3C::ID, W3C::IDREF, W3C::IDREFS, W3C::INT, W3C::INTEGER, W3C::LANGUAGE, W3C::LONG, W3C::NAME, W3C::NCNAME, W3C::NEGATIVEINTEGER, W3C::NMTOKEN, W3C::NMTOKENS, W3C::NONNEGATIVEINTEGER, W3C::NONPOSITIVEINTEGER, W3C::NORMALIZEDSTRING, W3C::NOTATION, W3C::POSITIVEINTEGER, W3C::QNAME, W3C::SHORT, W3C::STRING, W3C::TIME, W3C::TOKEN, W3C::UNSIGNEDBYTE, W3C::UNSIGNEDINT, W3C::UNSIGNEDLONG, W3C::UNSIGNEDSHORT
'XML::Parser' => '2.34', # STD::XML
'Pod::Find' => '0.24', # STD::POD

};

use CPAN;

    CPAN::Shell->install( keys %$prereq );


