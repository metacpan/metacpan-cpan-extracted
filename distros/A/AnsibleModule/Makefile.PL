use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'AnsibleModule',
  VERSION_FROM => 'lib/AnsibleModule.pm',
  PREREQ_PM => {'Mojolicious' => '5.62', 'App::FatPacker' => 0},
  AUTHOR       => 'Marcus Ramberg<mramberg@cpan.org>',
  LICENSE      => 'artistic_2',
  test         => {TESTS => 't/*.t'},
  EXE_FILES    => ['script/ansible-perl'],
);
