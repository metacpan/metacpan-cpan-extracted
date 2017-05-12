use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'Import vCards for use by App::Office::Contacts',
 ) : (),
 clean =>
 {
	 FILES => 'blib/* Makefile MANIFEST CGI-Office-Contacts-Import-vCards*'
 },
 dist =>
 {
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
 },
 DISTNAME  => 'CGI-Office-Contacts-Import-vCards',
 NAME      => 'App::Office::Contacts::Import::vCards',
 PL_FILES  => {},
 PREREQ_PM =>
 {
	App::Office::Contacts   => 1.06,
	Moose                   => 0.98,
	namespace::autoclean    => 0.09,
	Text::DoubleMetaphone   => 0,
	Text::GenderFromName    => 0,
	Test::Simple            => 0.94,
	Test::Pod               => 1.41,
	Text::vFile::toXML      => 0, # For importing vCards.
	XML::Handler::YAWriter  => 0, # For xmlpretty.
	XML::SAX::Base          => 0,
	XML::SAX::ParserFactory => 0,
 },
 VERSION_FROM	=> 'lib/CGI/Office/Contacts/Import/vCards.pm',
);
