use strict;
use warnings;

# This mirrors a real CPAN test (e.g. XML-Xerces' t/StdInInputSource.t): an END
# block is registered before a "use" of a module that is not installed. When
# Test::Vars requires the wrapped file the "use" fails to compile, but the END
# block is left registered and runs as the forked analyzer child exits. Here it
# calls ok(), which was never imported, so the child dies with a non-zero exit
# status. That non-zero status used to slip past the "file could not be
# analyzed, skip it" check and leak the Test::Vars "ignores ... because" note.
my $loaded;
END { ok( $loaded, 'module loaded' ) }

use This::Module::Does::Not::Exist;

$loaded = 1;

sub run {
    my $unused_after_missing = 1;
    return;
}
