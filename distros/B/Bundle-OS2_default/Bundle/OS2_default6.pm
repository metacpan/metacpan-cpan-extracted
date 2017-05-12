package Bundle::OS2_default6;

$VERSION = '1.01';

1;

=head1 NAME

Bundle::OS2_default6 - Miscelaneous modules for OS/2 binary distribution

=head1 SYNOPSIS

  perl -MCPAN -e "install Bundle::OS2_default6"

  perl_ -MCPAN -e "install Bundle::OS2_default6"

=head1 CONTENTS

File::CounterFile

Font::AFM

HTML::Tree

HTML::Tagset		- prereq of HTML::Parser, but makes life easier

HTML::Parser

Image::Size

IO::String		- Included later, but nicer to build it before Image::Info

IO::Stringy		- likewise for XML::Parser

Image::Info

MIME::Lite

MIME::Lite::HTML

Mail::Header		- prereq for MIME-tools

MIME::Head		- to get MIME-tools

MIME::Types

XML::Parser		- is in Bundle::XML, but makes testing quickier

XML::LibXML::Common	- likewise

XML::NamespaceSupport	- needed by XML::SAX, but not specified as dependency

XML::SAX		- prereq for LibXML

Unicode::String		- prereq for Bundle::XML, but makes testing quickier

XML::RegExp		- prereq for XML::DOM

XML::LibXML		- prereq for XML::DT

Bundle::XML

=head1 REMARKS

The following stuff can't be put in the L<CONTENTS> section:

  podlators

  PodParser

The explicit modules from distributions could be used:

Pod::Text::Color  - to get R/RR/RRA/podlators-1.09.tar.gz

Pod::InputObjects - to get B/BR/BRADAPP/PodParser-1.18.tar.gz

but these files are now included with the standard 5.6.1.

=cut

