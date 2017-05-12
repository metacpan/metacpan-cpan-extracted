use 5.007003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'AxKit::App::TABOO',
    'VERSION_FROM'	=> 'lib/AxKit/App/TABOO.pm', # finds $VERSION
    'PREREQ_PM'		=> { Data::Dumper => 0, # Deb: perl
			     DBI => 0, # Deb
			     DBD::Pg => 1.32, # Deb: libdbd-pg-perl
			     Exception::Class::DBI => 0,
			     Time::Piece => 0, # Deb: libtime-piece-perl
			     Class::Data::Inheritable => 0, # Deb: libclass-data-inheritable-perl
			     XML::LibXML => 1.57, # Deb: libxml-libxml-perl
			     AxKit => 1.62, # Deb, sarge: axkit
			     AxKit::XSP::QueryParam => 0.02,
                             AxKit::XSP::Sendmail => 0,
			     Crypt::GeneratePassword => 0,
			     Session => 0,
			     Apache::AxKit::Plugin::AddXSLParams::Request => 0,
			     Encode => 2.09, # Deb: perl
			     XML::LibXSLT => 0, # Deb: libxml-libxslt-perl
			     Apache::AxKit::Plugin::Param::Expr => 0,
			     MIME::Types => 0, # Deb: libmime-types-perl
			     Text::Unaccent => 1.07, # Deb: libtext-unaccent-perl
			     IDNA::Punycode => 0,
			     Net::Akismet => 0.02,
			     HTML::StripScripts => 1.04,
			     HTML::StripScripts::Parser => 1.02,
			     HTML::StripScripts::LibXML => 0.12,
			   }, # E.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
     (ABSTRACT_FROM => 'lib/AxKit/App/TABOO.pm', # retrieve abstract from module
      AUTHOR     => 'Kjetil Kjernsmo <kjetilk@cpan.org>') : ()),
);
