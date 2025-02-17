# Note: this file was auto-generated by Module::Build::Compat version 0.4232
require 5.014000;
use ExtUtils::MakeMaker;
WriteMakefile
(
  'NAME' => 'Bio::BPWrapper',
  'VERSION_FROM' => 'lib/Bio/BPWrapper.pm',
  'PREREQ_PM' => {
                   'Bio::DB::RefSeq' => 0,
                   'BioPerl' => '1.007008',
                   'Path::Tiny' => '0.058'
                 },
  'INSTALLDIRS' => 'site',
  'EXE_FILES' => [
                   'bin/bioaln',
                   'bin/biodb',
                   'bin/biopop',
                   'bin/bioseq',
                   'bin/biotree'
                 ],
  'PL_FILES' => {}
)
;
