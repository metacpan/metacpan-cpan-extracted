use 5.014002;

use Devel::CheckLib;
check_lib_or_exit( lib => 'rados', header => 'rados/librados.h' );

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Ceph::Rados',
    VERSION_FROM      => 'lib/Ceph/Rados.pm', # finds $VERSION
    CONFIGURE_REQUIRES  => {
        'Devel::CheckLib'       => 0,
        'ExtUtils::MakeMaker'   => 0,
    }, # e.g., Module::Name => 1.1
    TEST_REQUIRES     => {
        'Test::More'        => 0,
        'Test::Exception'   => 0,
        'Data::Dump'        => 0,
    },
    ABSTRACT_FROM     => 'lib/Ceph/Rados.pm', # retrieve abstract from module
    AUTHOR            => 'Alex <alex@openimp.com>',
    LIBS              => ['-lrados'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(CEPH_OSD_TMAP_CREATE CEPH_OSD_TMAP_HDR CEPH_OSD_TMAP_RM
		 CEPH_OSD_TMAP_SET LIBRADOS_CREATE_EXCLUSIVE
		 LIBRADOS_CREATE_IDEMPOTENT LIBRADOS_LOCK_FLAG_RENEW
		 LIBRADOS_OP_FLAG_EXCL LIBRADOS_OP_FLAG_FAILOK
		 LIBRADOS_SNAP_DIR LIBRADOS_SNAP_HEAD LIBRADOS_SUPPORTS_WATCH
		 LIBRADOS_VERSION_CODE LIBRADOS_VER_EXTRA LIBRADOS_VER_MAJOR
		 LIBRADOS_VER_MINOR),
              {name=>"LIBRADOS_CMPXATTR_OP_EQ", macro=>"1"},
              {name=>"LIBRADOS_CMPXATTR_OP_GT", macro=>"1"},
              {name=>"LIBRADOS_CMPXATTR_OP_GTE", macro=>"1"},
              {name=>"LIBRADOS_CMPXATTR_OP_LT", macro=>"1"},
              {name=>"LIBRADOS_CMPXATTR_OP_LTE", macro=>"1"},
              {name=>"LIBRADOS_CMPXATTR_OP_NE", macro=>"1"},
              {name=>"LIBRADOS_OPERATION_BALANCE_READS", macro=>"1"},
              {name=>"LIBRADOS_OPERATION_IGNORE_CACHE", macro=>"1"},
              {name=>"LIBRADOS_OPERATION_IGNORE_OVERLAY", macro=>"1"},
              {name=>"LIBRADOS_OPERATION_LOCALIZE_READS", macro=>"1"},
              {name=>"LIBRADOS_OPERATION_NOFLAG", macro=>"1"},
              {name=>"LIBRADOS_OPERATION_ORDER_READS_WRITES", macro=>"1"},
              {name=>"LIBRADOS_OPERATION_SKIPRWLOCKS", macro=>"1"});
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Ceph::Rados',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

sub MY::postamble {
    return "\$(XS_FILES): ".join(" ", <XS/*.xs>)."\n\ttouch \$(XS_FILES)";
}
