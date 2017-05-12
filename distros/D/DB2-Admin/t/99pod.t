#
# Morgan Stanley versioning - ignore
#
BEGIN {
    if ($ENV{ID_EXEC}) {
	require "MSDW/Version.pm";
	MSDW::Version->import('Test-Pod'    => '1.20',
			      'Test-Simple' => '0.60',
			      'Pod-Escapes' => '1.04',
			      'Pod-Simple'  => '3.04',
			     );
    }
}
use Test::Pod tests => 1;

pod_file_ok("lib/DB2/Admin.pm");
