use 5.006;
use ExtUtils::Constant;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              OPTIMIZE => '-g',
              NAME              => 'Cache::Memcached::GetParserXS',
              VERSION_FROM      => 'lib/Cache/Memcached/GetParserXS.pm', # finds $VERSION
              PREREQ_PM         => {
                  'Cache::Memcached' => 1.21,
                  'ExtUtils::Constant' => 0,
              }, # e.g., Module::Name => 1.1
              ABSTRACT_FROM  => 'lib/Cache/Memcached/GetParserXS.pm', # retrieve abstract from module
              AUTHOR         => 'Jonathan Steinert <hachi@cpan.org>',
              LIBS              => [''], # e.g., '-lm'
              DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
              INC               => '-I.', # e.g., '-I. -I/usr/include/other'
              # Un-comment this if you add C files to link with later:
              # OBJECT            => '$(O_FILES)', # link all the C files too
              clean             => { FILES => "const-c.inc const-xs.inc" },
              );

my @names = (qw(DEST NSLEN ON_ITEM BUF STATE OFFSET FLAGS KEY FINISHED));
ExtUtils::Constant::WriteConstants(
                                   NAME         => 'Cache::Memcached::GetParserXS',
                                   NAMES        => \@names,
                                   DEFAULT_TYPE => 'IV',
                                   C_FILE       => 'const-c.inc',
                                   XS_FILE      => 'const-xs.inc',
                                );

