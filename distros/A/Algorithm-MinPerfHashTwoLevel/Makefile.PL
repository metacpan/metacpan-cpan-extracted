use ExtUtils::MakeMaker;
use strict;
use warnings;
no warnings 'portable';
use Config;

os_unsupported() unless $Config{d_mmap}; # we use mmap
die "requires 64-bit integer support (little-endian)\n"
    unless eval {
        my $int= 0x1234567801234567;
        my $str= "gE#\1xV4\22";
        my $packed= pack "Q", $int;
        my $unpacked= unpack "Q", $str;
        (($packed eq $str) && ($unpacked eq $int))
    };
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Algorithm::MinPerfHashTwoLevel',
    VERSION_FROM      => 'lib/Algorithm/MinPerfHashTwoLevel.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Algorithm/MinPerfHashTwoLevel.pm', # retrieve abstract from module
       AUTHOR         => 'Yves Orton <yorton@(none)>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OPTIMIZE          => '-O3',
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    META_MERGE => {
        resources => {
            repository => {
              url => 'git://github.com/demerphq/Algorithm-MinPerfHashTwoLevel.git',
            },
            bugtracker => {
              web => 'https://github.com/demerphq/Algorithm-MinPerfHashTwoLevel/issues',
            },
        },
        'meta-spec' => { version => 2 },
    },
);
