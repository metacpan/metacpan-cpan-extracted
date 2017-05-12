use ExtUtils::MakeMaker;
use 5.010;
my @scripts = ('bin/thesaurus2any',
	       'bin/thesaurus2htmls',
	       'bin/tag2thesaurus',
	       'bin/tax2thesaurus',
	       'bin/thesaurusTranslate',
	       'bin/thesaurus2tex');

my %reqmodules = ('Test::More' => 0,
                  'CGI'        => 0,
                  'Storable'   => '1.0006');

## Test for XML::TMX

my $V = eval {
  require XML::TMX;
  $XML::TMX::VERSION 
};

if ($@) {
  print "It seems you do not have XML::TMX. Not installing thesaurus2TMX script.\n";
} else {
  if ($V >= 0.12) {
    push @scripts, 'bin/thesaurus2TMX';
    $reqmodules{'XML::TMX'} = '0.12';
    print "XML::TMX found. Installing thesaurus2TMX script\n";
  } else {
    print "It seems you do not have XML::TMX >= 0.12. Not installing thesaurus2TMX script.\n";
  }
}


WriteMakefile(
	      'NAME'	     => 'Biblio::Thesaurus',
	      'VERSION_FROM' => 'lib/Biblio/Thesaurus.pm',
          'ABSTRACT_FROM' => 'lib/Biblio/Thesaurus.pm',
	      'EXE_FILES'    => [@scripts],
	      'PREREQ_PM'    => {%reqmodules},
	     );
