# -*- mode: perl -*-

use Test::More tests => 3;

## this tests the useability of the package
## also, tests the version number of bzlib, although the 
## boot code should bail if the version isn't right

BEGIN {
  use_ok('Compress::Bzip2');
};

my $fail;
foreach my $constname (qw(
	BZ_CONFIG_ERROR BZ_DATA_ERROR BZ_DATA_ERROR_MAGIC BZ_FINISH
	BZ_FINISH_OK BZ_FLUSH BZ_FLUSH_OK BZ_IO_ERROR BZ_MAX_UNUSED
	BZ_MEM_ERROR BZ_OK BZ_OUTBUFF_FULL BZ_PARAM_ERROR BZ_RUN BZ_RUN_OK
	BZ_SEQUENCE_ERROR BZ_STREAM_END BZ_UNEXPECTED_EOF)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Compress::Bzip2 macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }
}

ok( !$fail, "constants imported ok" );

my $version = bzlibversion();
ok( $version && $version =~ /^1\./, "bzlib version is $version" );

