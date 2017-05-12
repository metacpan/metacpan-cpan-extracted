package Bundle::WeBWorK;

$VERSION = '0.01';

1;

__END__

=head1 NAME

Bundle::WeBWorK- A bundle of the modules required for the WeBWorK online
homework system.

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::WeBWorK'>

=head1 CONTENTS

Data::UUID

Date::Format

Date::Parse

DateTime

DBI

Digest::MD5

Email::Address

Exception::Class

HTML::Entities

HTML::Tagset

HTML::Template

Iterator

Iterator::Util

JSON

Locale::Maketext::Lexicon

Mail::Sender

Net::IP

Net::LDAPS

PadWalker

PHP::Serialization

Pod::WSDL

SOAP::Lite

SQL::Abstract

String::ShellQuote

Tie::IxHash

Time::Zone

URI::Escape

UUID::Tiny

XML::Parser

XML::Parser::EasyTree

XML::Writer

XMLRPC::Lite

=head1 DESCRIPTION

This bundle installs many of the non-core perl prerequisites for WeBWorK, an 
open source online homework system for math and science courses.  WeBWorK also 
requires mod_perl2, some libapreq2 (Apache2::*) modules, DBD::mysql, and GD 
but I left those out because IMHO it can take some sophistication to install 
those from source, especially if you did not install apache2, mysql, and 
libgd from source.  In particular, if you installed apache2, mysql and libgd 
from a package manager, then also install mod_perl2, the libapreq2 perl 
modules, DBD::mysql, and GD from your package manager.

For more information, see

http://webwork.maa.org/wiki

for documentation and 

http://github.com/openwebwork

for the code.

=head1 AUTHOR

Jason Aubrey, <aubreyja@cpan.org>

