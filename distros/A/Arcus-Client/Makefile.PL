use 5.014000;
use ExtUtils::MakeMaker;
use Cwd 'abs_path';
use FindBin '$Bin';
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $cache_hit = $ARGV[0] =~ /CACHE_HIT=(\d+)/ ? $1 : 0;
system("./deps/install.sh") unless $cache_hit;

my $src_path = abs_path($FindBin::Bin);
WriteMakefile(
  NAME                      => 'Arcus::Base',
  DISTNAME                  => 'Arcus-Client',
  VERSION                   => '0.5.0',
  LICENSE                   => 'perl_5',
  ABSTRACT                  => 'Perl client for arcus cache cluster',
  PREREQ_PM                 => {
    'Digest::SHA'           => 0,
    'POSIX::AtFork'         => 0,
    'parent'                => 0,
    'XSLoader'              => 0,
  },
  AUTHOR                    => 'JaM2in <koo05131@jam2in.com>',
  LIBS                      => ["-L$src_path/lib/Arcus/Deps/lib -lmemcached -lmemcachedutil"], # e.g., '-lm'
  INC                       => "-I$src_path/lib/Arcus/Deps/include",
  dynamic_lib               => { OTHERLDFLAGS => "-Wl,-rpath,$src_path/lib/Arcus/Deps/lib,-rpath,\$(DESTINSTALLSITEARCH)/Arcus/Deps/lib" },
  TEST_REQUIRES             => {
    'Test::More'            => 0,
    'Test::Deep'            => 0,
    'IO::Socket::PortState' => 0,
  },
);
