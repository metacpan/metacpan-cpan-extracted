use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'DBIx::Class::Schema::Loader::Dynamic',
  VERSION_FROM => 'lib/DBIx/Class/Schema/Loader/Dynamic.pm',
  ABSTRACT     => 'Really Dynamic Schema Generation for DBIx::Class',
  AUTHOR       => 'Frank Carnovale <frankc@cpan.org>',
  LICENSE      => 'artistic_2',
  PREREQ_PM    => {
    'DBIx::Class::Schema::Loader' => '0.07045',
    'Test::Most' => '0',
  },
  test         => {TESTS => 't/*.t'},
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => ['t']},
    prereqs        => {runtime => {requires => {perl => '5.010001'}}},
    resources    => {
        bugtracker => {web => 'https://github.com/frank-carnovale/DBIx-Class-Schema-Loader-Dynamic/issues'},
        license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
        repository => {
            type => 'git',
            url  => 'https://github.com/frank-carnovale/DBIx-Class-Schema-Loader-Dynamic.git',
            web  => 'https://github.com/frank-carnovale/DBIx-Class-Schema-Loader-Dynamic',
        },
    },
  },
);
