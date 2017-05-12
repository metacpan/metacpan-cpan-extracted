use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my $author1 = 'Bridget McInnes <btmcinnes@vcu.edu';
my $author2 = 'Nick	Jordan'; 

WriteMakefile(
    NAME                => 'Algorithm::LDA',
    VERSION_FROM        => 'lib/Algorithm/LDA.pm',
    PREREQ_PM => {
        'JSON::XS' => 0,
		'List::Util' => 0,
		'List::MoreUtils' => 0,
		'Class::Accessor::Fast' => 0,
    }, 

    EXE_FILES           => [("bin/lda.pl")], 
    dist              => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
    ($] >= 5.005 ?
     (
      AUTHOR          => "$author1, $author2") : ())); 
 
