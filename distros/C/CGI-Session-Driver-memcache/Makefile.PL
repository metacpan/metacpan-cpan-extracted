use ExtUtils::MakeMaker;
#
#require 5.6;

WriteMakefile(
  'NAME'         => 'CGI::Session::Driver::memcache',  #  module name (Mod::Pack)
  #'DISTNAME' => '', # Explicit dist filename
  'VERSION_FROM' => 'memcache.pm', # finds $VERSION
  'ABSTRACT'     => 'Store Web/CGI Sessions on a memcached',
  #ABSTRACT_FROM
  'AUTHOR'       => 'Olli Hollmen',
  # Class name => ver
  'PREREQ_PM'    => {
    'Data::Dumper' => 0,
    'CGI' => 0,
    'CGI::Session' => 0,

  },
  # Ref to executables to be copied to INST_SCRIPT directory
  # 'EXE_FILES' => [],
  # Mapping of XS to C files
  #'XS' => {'CGI::Session::Driver::memcache.xs' => 'CGI::Session::Driver::memcache.c'},
  #'XSOPT' => '-extern',
  #'TYPEMAPS' => ['','']
);

