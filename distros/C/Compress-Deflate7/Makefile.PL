use 5.012000;
use ExtUtils::MakeMaker;
use File::Basename;

my %options = (
    NAME              => 'Compress::Deflate7',
    VERSION_FROM      => 'lib/Compress/Deflate7.pm', # finds $VERSION
    PREREQ_PM         => {
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Compress/Deflate7.pm', # retrieve abstract from module
       AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    INC               => '-I7zip/CPP', # e.g., '-I/usr/include/other'

    XSOPT             => '-C++',

	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too

    LICENSE           => 'lgpl',
    'dist'            => {
      PREOP     => 'chmod 600 Makefile.PL',
      TARFLAGS	=> '--group=none --owner=bjoern -cvf',
      COMPRESS  => 'gzip -9',
    },
    XS => { 'Deflate7.xs' => 'Deflate7.c' },
    C => [
    ],
    clean => { FILES => [], },
);

if ($^O eq "MSWin32")
{
  $options{CC}   = "cl -TP -EHsc";

} else {
  # assume some compatible Linux
  $options{LD}   = "g++";
  $options{CC}   = "g++";
}

my @C = (
# '7zip/CPP/7zip/Common/MyInitGuid.h',
'7zip/CPP/7zip/Common/InBuffer.cpp',
'7zip/CPP/7zip/Common/OutBuffer.cpp',
'7zip/CPP/7zip/Common/StreamObjects.cpp',
'7zip/CPP/7zip/Common/StreamUtils.cpp',
'7zip/CPP/7zip/Compress/BitlDecoder.cpp',
'7zip/CPP/7zip/Compress/DeflateDecoder.cpp',
'7zip/CPP/7zip/Compress/DeflateEncoder.cpp',
'7zip/CPP/7zip/Compress/LzOutWindow.cpp',
'7zip/CPP/7zip/Compress/ZlibDecoder.cpp',
'7zip/CPP/7zip/Compress/ZlibEncoder.cpp',
'7zip/C/Alloc.c',
'7zip/C/HuffEnc.c',
'7zip/C/LzFind.c',
'7zip/C/Sort.c',
);

foreach my $c (@C) {
  my ($name) = fileparse($c);
  open F, ">$name";
  print F qq|#include "$c"\n|;
  close F;
  push @{ $options{C} }, $name;
  push @{ $options{clean}{FILES} }, $name;
}
push @{ $options{C} }, values %{$options{XS}};

WriteMakefile(%options);
