use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'CPU::Emulator::Z80',
    VERSION_FROM => 'lib/CPU/Emulator/Z80.pm',
    PREREQ_PM => {
        'CPU::Emulator::Memory::Banked' => 1.1,
        'Tie::Hash::Vivify'             => 0.01,
        'Scalar::Util'                  => 0,
        'YAML::Tiny'                    => 1.25,
    }
);
