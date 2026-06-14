use strict;

use ExtUtils::MakeMaker qw(WriteMakefile);
use File::Spec::Functions;
use Getopt::Long;

my (@CCFLAGS, @INC, @LIBS);

push @INC, '-Iinclude', '-Isrc';
if( $^O eq 'MSWin32' ) {
push @LIBS, '-Lwin32/ -lzlib';
}
else {
push @CCFLAGS, '-Wdeclaration-after-statement';
push @LIBS, '-lz';
}

my $inc_files = join(' ', glob 'include/*.h');
my $src_files = join(' ', glob 'src/*.c');

WriteMakefile(
    NAME              => 'Audio::Scan',
    VERSION_FROM      => 'lib/Audio/Scan.pm',
    PREREQ_PM         => { 'Test::Warn' => 0 },
    ABSTRACT_FROM     => 'lib/Audio/Scan.pm',
    AUTHOR            => 'Andy Grundman <andy@hybridized.org>',
    CCFLAGS           => "$Config::Config{ccflags} " . join(' ', @CCFLAGS),
    INC               => join(' ', @INC),
    LIBS              => [ join(' ', @LIBS) ],
    depend            => { 'Scan.c' => "$inc_files $src_files" },
    LICENSE           => 'gpl_2',
);
