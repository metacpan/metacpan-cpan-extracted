use ExtUtils::MakeMaker;
use File::Copy;

if ($^V lt v5.10) {
   die("Algorithm::RandomPointGenerator has only been tested on Perl 5.10.1.\n" .
   "Your perl version is $].\n");
}

copy("perl/MANIFEST.perl","MANIFEST");

WriteMakefile(
    NAME         => 'Algorithm::RandomPointGenerator',
    VERSION_FROM => 'lib/Algorithm/RandomPointGenerator.pm',
    PREREQ_PM    => { Math::Random => '0.71',
                      Graphics::GnuplotIF => '1.6',
                      Math::Big => '1.12',
                      List::Util => '1.39',
                    },
    AUTHOR       => 'Avinash Kak (kak@purdue.edu)',
    ABSTRACT     => 'This module generates a set of random points in a 2D plane according to a user-specified probability distribution that is supplied to the module as a 2D histogram in a CSV file',
    clean        => {FILES => join(" ",
                                   map { "$_ */$_ */*/$_" }
                                   qw( *% *.html *.b[ac]k *.old *.orig ) )
                    },
);
