package CPANPLUS::Internals::Utils::Autoflush;

use vars qw[$VERSION];
$VERSION = "0.9916";

BEGIN { my $old = select STDERR; $|++; select $old; $|++; };

1;
