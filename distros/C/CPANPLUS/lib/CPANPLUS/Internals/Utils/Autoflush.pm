package CPANPLUS::Internals::Utils::Autoflush;

use vars qw[$VERSION];
$VERSION = "0.9908";

BEGIN { my $old = select STDERR; $|++; select $old; $|++; };

1;
