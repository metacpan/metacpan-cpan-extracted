use strict;
use warnings;

use Test::More tests => 2;
use Text::ParseWords qw/shellwords/;

BEGIN { use_ok( 'Alien::NSS' ); }

diag("Libs: ".Alien::NSS->libs);
diag("Cflags: ".Alien::NSS->cflags);
diag("Install type: ".Alien::NSS->install_type);

my %libs = map { $_ => 1 } shellwords( Alien::NSS->libs );
ok(defined($libs{'-lnss3'}), 'Libnss defined');
#my @alienlibs = grep { /\_alien/ } keys %libs;
#ok(scalar @alienlibs == 0, 'No libs in _alien');
