use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{CP932NEC::R2},
    'VERSION'   => q{0.05},
    'ABSTRACT'  => q{provides minimal CP932NEC I/O subroutines by short name},
    'PREREQ_PM' => {
        'ExtUtils::MakeMaker' => '5.4302',
        'File::Basename' => '2.6',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'FindBin' => '1.42',
        'IOas::CP932NEC' => '0.04',
        'Socket' => '0',
        'UTF8::R2' => '0.03',
        'lib' => '0',
        'perl' => '5.005_03',
        'strict' => '1.01',
        'vars' => '0',
    },
    'AUTHOR'    => q{ina <ina@cpan.org> in a CPAN},
);

__END__
