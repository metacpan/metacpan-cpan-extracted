use ExtUtils::MakeMaker;
use File::Copy;

if ($^V lt v5.10) {
   die("Algorithm::LinearManifoldDataClusterer has only been tested on Perl 5.10.1.\n" .
   "Your perl version is $].\n");
}

copy("perl/MANIFEST.perl","MANIFEST");

WriteMakefile(
    NAME         => 'Algorithm::LinearManifoldDataClusterer',
    VERSION_FROM => 'lib/Algorithm/LinearManifoldDataClusterer.pm',
    PREREQ_PM    => { Math::Random => "0.71",
                      Graphics::GnuplotIF => "1.6",
                      Math::GSL::Matrix => 0,
                      List::Util => "1.39",
                      POSIX => "1.32",
                      File::Basename => "2.84",
                    },
    AUTHOR       => 'Avinash Kak (kak@purdue.edu)',
    ABSTRACT     => 'A Perl module for clustering data that resides on a low-dimensional manifold in a high-dimensional measurement space',
    clean        => {FILES => join(" ",
                                   map { "$_ */$_ */*/$_" }
                                   qw( *% *.html *.b[ac]k *.old *.orig ) )
                    },
);
