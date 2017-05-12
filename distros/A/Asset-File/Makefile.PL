use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME           => 'Asset::File',
   AUTHOR         => '扶凯 <iakuf@163.com>',
   PL_FILES       => {},
   LICENSE        => "perl",
   DISTNAME       => 'Asset-File',
   VERSION_FROM   => 'lib/Asset/File.pm',
   PREREQ_PM      => { 
        'Moo'         => 0,
        'File::Copy'  => 0, 
        'File::Temp'  => 0,
        'Digest::MD5' => 0, 
        'IO::File'    => 0,
        'Test::More'  => 0,
        'Digest::SHA1' => 0,
        'File::Basename' => 0,
        'File::Path' => 0,
        'File::Spec::Functions' => 0,
   },
   dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   clean          => { FILES => 'Asset-File-*' },
   META_MERGE     => {
   },
);
