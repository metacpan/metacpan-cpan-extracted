use ExtUtils::MakeMaker;
use File::Copy;

#if ($^V lt v5.10) {
#   die("Algorithm::BitVector has only been tested on Perl 5.10.1.\n" .
#   "Your perl version is $].\n");
#}

copy("perl/MANIFEST.perl","MANIFEST");

WriteMakefile(
    NAME         => 'Algorithm::BitVector',
    VERSION_FROM => 'lib/Algorithm/BitVector.pm',
    PREREQ_PM    => { Math::Random => 0,
                      Math::BigInt => 0,
                      List::Util => 1.33,
                      Fcntl => 0,
                    },
    AUTHOR       => 'Avinash Kak (kak@purdue.edu)',
    ABSTRACT     => 'A Perl module for constructing memory efficient packed representations of bit vectors from different data types, and for logical and arithmetic operations on such vectors',
    clean        => {FILES => join(" ",
                                   map { "$_ */$_ */*/$_" }
                                   qw( *% *.html *.b[ac]k *.old *.orig ) )
                    },
);
