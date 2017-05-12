# $Id: 00pod.t,v 1.1 2003/03/21 05:35:57 koschei Exp $
use strict;
use vars qw( @files );

BEGIN {
    @files = qw(
	Excel.pm
    );
}
use Test::More tests => scalar @files;
eval "use Test::Pod 0.95";
SKIP: {
    skip "Test::Pod 0.95 not installed.", 1 if $@;
    chdir(-d "lib/DateTime/Format" ? "lib/DateTime/Format" : "../lib/DateTime/Format");
    pod_file_ok( $_, "Valid POD file: $_" ) for @files;
}
