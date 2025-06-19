use ExtUtils::MakeMaker;

require 5.026;

my $VERSION = '0.200';

my %prereq =  # also included in t/00use.t
  (	'DateTime'			=> 0
  , 'DateTime::Format::ISO8601'	=> 0
  , 'DateTime::Format::Mail'	=> 0
  , 'Devel::GlobalDestruction'  => 0
  , 'HTTP::Status'		=> 6.39
  , 'JSON'				=> 0
  , 'List::Util'		=> 0
  , 'Log::Report'		=> 0
  , 'MIME::Base64'		=> 0
# , 'Mojo::URL'			=> 0   has no version, part of Mojolicious
# , 'Mojo::UserAgent'	=> 0   has no version, part of Mojolicious
  , 'Mojolicious'		=> 0
  , 'Scalar::Util'		=> 0
  , 'Storable'			=> 0
  , 'URI'				=> 0
  );

WriteMakefile
  ( NAME       => 'Couch::DB'
  , VERSION    => $VERSION
  , AUTHOR     => 'Mark Overmeer'
  , ABSTRACT   => 'thick CouchDB interface'
  , PREREQ_PM  => \%prereq
  , LICENSE    => 'perl_5'

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Couch-DB.git'
              , web  => 'https://github.com/markov2/perl5-Couch-DB'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/couch-db/raw
DISTDIR         = ../public_html/couch-db/source
EXTENDS         = 

# for POD
FIRST_YEAR      = 2024
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

# for HTML
HTML_OUTPUT     = ../public_html/couch-db/html
HTML_DOCROOT    = /couch-db/html
HTML_PACKAGE    = ../public_html/couch-db/htmlpkg

reference::
	bin/reference-table >reference.html
	cp reference.html ../public_html/couch-db/reference.html

__POSTAMBLE
