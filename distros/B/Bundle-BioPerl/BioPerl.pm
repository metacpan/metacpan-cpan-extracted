package Bundle::BioPerl;

$VERSION = '2.1.9';

1;

__END__

=head1 NAME

Bundle::BioPerl - A bundle to install external CPAN modules used by BioPerl 1.5.2

=head1 SYNOPSIS


Perl one liner using CPAN.pm:

  perl -MCPAN -e 'install Bundle::BioPerl'

Use of CPAN.pm in interactive mode:

  $> perl -MCPAN -e shell
  cpan> install Bundle::BioPerl
  cpan> quit

Just like the manual installation of perl modules, the user may
need root access during this process to insure write permission 
is allowed within the intstallation directory.


=head1 CONTENTS

    Algorithm::Munkres

    Bio::Phylo

    Class::AutoClass 1.01

    Clone

    Convert::Binary::C

    Data::Stag::Writer
    
    DB_File

    DBD::mysql

    GD::SVG	- Optional, used to generate SVG output in Bio::Graphics

    GD 1.3	- Used only for drawing things within the Bio::Graphics modules

    Graph::Directed	- This module is used for Ontology Engine implementation for the GO parser

    GraphViz

    HTML::Entities

    HTML::HeadParser

    HTML::Parser 3.0	- recommended, used to parse GDP page in Bio::DB::GDP

    HTML::TableExtract

    HTTP::Request::Common - recommended, used for web access (part of libwww-perl)

    IO::String

    IO::Scalar

    List::MoreUtils

    LWP::UserAgent	- recommended, used for web access

    PostScript::TextBlock

    Scalar::Util

    Set::Scalar

    SOAP::Lite	- Used for bibliographic queries & XEMBLService modules

    Sort::Naturally

    Spreadsheet::ParseExcel

    Storable	- recommended for all bioperl releases after 0.7.2. Used for persistant storage of objects and local file caching

    SVG 2.26	- Optional, used to generate SVG output in Bio::Graphics

    SVG::Graph 0.01	- Optional, used to generate SVG output in Bio::Graphics

    Text::ParseWords	- Recommended, used in Bio::Graphics

    XML::DOM

    XML::DOM::XPath

    XML::LibXML

    XML::Parser

    XML::Parser::PerlSAX	- recommended for all bioperl releases after 0.6.2

    XML::SAX

    XML::SAX::Writer

    XML::Simple

    XML::Twig	- recommended for all bioperl releases after 0.6.2

    XML::Writer	- recommended for all bioperl releases after 0.6.2

    YAML

=head1 DESCRIPTION

The BioPerl distribution from http://bioperl.org contains code and
modules that may use or require additional 'external' perl modules 
for advanced functionality. Many of the external modules are not
contained within the standard Perl distribution. These external 
modules can be obtained from the Comprehensive Perl Archive 
Network (CPAN) located at http://www.cpan.org. 

NOTE: The latest release of this bundle includes all of the
external CPAN modules that are listed as dependencies of the
official BioPerl 1.5.2 codebase release. 

The only exceptions are the DBD:: and DBI:: modules which are really 
best off installed on their own if you have a need to load and 
query relational. databases.

These modules are not required - they greatly extend the functionality
of bioperl in various ways. To get the best use of bioperl, particularly
after the release of BioPerl 1.0 we recommend at least having the
LWP:: network access and the XML:: related modules installed. 

This perl module (Bundle::BioPerl) contains NO functionality
or real code at all. It is essentially a special perl module
meant to be used by the CPAN.pm module to simplify the task of
automatically installing multiple modules in one easy step.

Essentially users can tell CPAN.pm to 'install Bundle::BioPerl' and
CPAN.pm will download, install and configure all of the modules listed
in the BioPerl Bundle module. See the SYNOPSIS section or do
C<perldoc CPAN> to learn about how to use the CPAN.pm module to install
bundles.

NOTE: This process is complicated by the fact that some BioPerl
external modules themselves have their own dependencies and
prerequisites. In particular the XML::Parser module requires
the prior installation of the 'xpat' package which resides
outside of CPAN at http://sourceforge.net/projects/expat/.

The C<install Bundle::BioPerl> process may need to be repeated
several times to complete the full installation of all listed
modules. Some external modules are complicated or may themselves
have dependencies. 

NOTE: This Bundle does not install BioPerl :) Just the additional
modules that BioPerl code ocasionally makes use of. You will still
need to get the BioPerl distribution from CPAN or http://bioperl.org
and install it the usual way:

  perl Makefile.PL
  make
  make test
  make install

CPAN.pm has many features - including the ability to download
but not install the modules listed in the BioPerl bundle. 

C<perldoc CPAN> is your friend :)

=head1 AUTHOR

Chris Dagdigian E<lt>F<dag@sonsorol.org>E<gt>
(Author only of this bundle, not any the modules it lists)

=cut
