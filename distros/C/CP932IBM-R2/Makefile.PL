use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{CP932IBM::R2},
    'VERSION'   => q{0.07},
    'ABSTRACT'  => q{provides minimal CP932IBM I/O subroutines by short name},
    'PREREQ_PM' => {
        'ExtUtils::MakeMaker' => '5.4302',
        'File::Basename' => '2.6',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'FindBin' => '1.42',
        'IOas::CP932IBM' => '0.06',
        'Socket' => '0',
        'UTF8::R2' => '0.05',
        'lib' => '0',
        'perl' => '5.005_03',
        'strict' => '1.01',
        'vars' => '0',
    },
    'AUTHOR'    => q{ina <ina@cpan.org>},
);

__END__
