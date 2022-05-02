use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'CPU::Emulator::Z80',
    META_MERGE => {
        license => 'open_source',
        resources => {
	    repository => 'https://github.com/DrHyde/perl-modules-CPU-Emulator-Z80',
	    bugtracker => 'https://github.com/DrHyde/perl-modules-CPU-Emulator-Z80/issues'
        }
    },
    VERSION_FROM => 'lib/CPU/Emulator/Z80.pm',
    PREREQ_PM => {
        'CPU::Emulator::Memory::Banked' => 1.1,
        'Tie::Hash::Vivify'             => 0.01,
        'Scalar::Util'                  => 0,
        'YAML::Tiny'                    => 1.25,
    }
);
