use ExtUtils::MakeMaker;
use File::Copy;

if ($^V lt v5.10) {

   die("Algorithm::ExpectationMaximization has been tested on Perl 5.10.0.\n" .
   "Your perl version is $].\n");
}

copy("perl/MANIFEST.perl","MANIFEST");

WriteMakefile(
    NAME         => 'Algorithm::ExpectationMaximization',
    VERSION_FROM => 'lib/Algorithm/ExpectationMaximization.pm',
    PREREQ_PM    => { Math::Random => '0.71',
                      Graphics::GnuplotIF => '1.4',
                      Math::GSL => '0.26',
                    },
    AUTHOR       => 'Avinash Kak (kak@purdue.edu)',
    ABSTRACT     => 'A Perl implementation of the Expectation Maximization algorithm for clustering numerical data',
    clean        => {FILES => join(" ",
                                   map { "$_ */$_ */*/$_" }
                                   qw( *% *.html *.b[ac]k *.old *.orig ) )
                    },
);
