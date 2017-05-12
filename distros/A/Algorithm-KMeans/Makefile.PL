use ExtUtils::MakeMaker;
use File::Copy;

#if ($^V lt v5.10) {
#   die("Algorithm::KMeans has only been tested on Perl 5.10.1.\n" .
#   "Your perl version is $].\n");
#}

copy("perl/MANIFEST.perl","MANIFEST");

WriteMakefile(
    NAME         => 'Algorithm::KMeans',
    VERSION_FROM => 'lib/Algorithm/KMeans.pm',
    PREREQ_PM    => { Math::Random => '0.71',
                      Graphics::GnuplotIF => '1.6',
                      Math::GSL => '0.32',
                    },
    AUTHOR       => 'Avinash Kak (kak@purdue.edu)',
    ABSTRACT     => 'A Perl Module for K-Means Clustering',
    clean        => {FILES => join(" ",
                                   map { "$_ */$_ */*/$_" }
                                   qw( *% *.html *.b[ac]k *.old *.orig ) )
                    },
);
