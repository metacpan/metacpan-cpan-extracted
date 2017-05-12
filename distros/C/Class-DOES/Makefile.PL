use ExtUtils::MakeMaker;

BEGIN { require 5.006001 }

my @MM = (
    NAME            => "Class::DOES",
    VERSION_FROM    => "lib/Class/DOES.pm",
    PREREQ_PM       => { 
        "Scalar::Util"  => "1.00",
        "Test::More"    => "0.45",
    },
);

# Hmm, this is fun.

$ExtUtils::MakeMaker::VERSION >= 6.11 and @MM = (@MM,
    AUTHOR          => "Ben Morrow <ben\@morrow.me.uk>",
    ABSTRACT_FROM   => "lib/Class/DOES.pm",
);

$ExtUtils::MakeMaker::VERSION >= 6.31 and @MM = (@MM,
    LICENSE         => "perl",
);

$ExtUtils::MakeMaker::VERSION >= 6.48 and @MM = (@MM,
    MIN_PERL_VERSION => "5.006001",
    META_MERGE => {
        resources => {
            bugtracker  => "http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-DOES",
            repository  => "http://github.com/mauzo/Class-DOES",
        },
    },
);

WriteMakefile(@MM);
