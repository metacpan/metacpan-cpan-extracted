# Note: this file was auto-generated by Module::Build::Compat version 0.4224
require 5.016000;
use ExtUtils::MakeMaker;
WriteMakefile
(
  'NAME' => 'Data::ObjectStore',
  'VERSION_FROM' => 'lib/Data/ObjectStore.pm',
  'PREREQ_PM' => {
                   'Data::RecordStore' => '6.04',
                   'Module::Build' => '0.4',
                   'Test::More' => 0
                 },
  'INSTALLDIRS' => 'site',
  'EXE_FILES' => [
                   'bin/class_mapper.pl',
                   'bin/objectstore_explorer',
                   'bin/objectstore_upgrade'
                 ],
  'PL_FILES' => {}
)
;
