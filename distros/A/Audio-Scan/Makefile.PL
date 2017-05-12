use strict;

use ExtUtils::MakeMaker qw(WriteMakefile);
use File::Spec::Functions;
use Getopt::Long;

my (@INC, @LIBS);

push @INC, '-Iinclude', '-Isrc';
push @LIBS, '-lz';

my $inc_files = join(' ', glob 'include/*.h');
my $src_files = join(' ', glob 'src/*.c');

WriteMakefile(
    NAME              => 'Audio::Scan',
    VERSION_FROM      => 'lib/Audio/Scan.pm',
    PREREQ_PM         => { 'Test::Warn' => 0 },
    ABSTRACT_FROM     => 'lib/Audio/Scan.pm',
    AUTHOR            => 'Andy Grundman <andy@hybridized.org>',
    INC               => join(' ', @INC),
    LIBS              => [ join(' ', @LIBS) ],
    depend            => { 'Scan.c' => "$inc_files $src_files" },
);
