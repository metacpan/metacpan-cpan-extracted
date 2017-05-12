use strict;
use warnings;
use File::Path;
use Test::More tests => 7;
use_ok("CPAN::Unpack");

rmtree("t/unpacked");
ok( !-d "t/unpacked", "No t/unpacked at the start" );

my $u = CPAN::Unpack->new;
$u->cpan("t/cpan/");
$u->destination("t/unpacked/");
$u->unpack;

ok( -d "t/unpacked" );
ok( -d "t/unpacked/Acme-Buffy" );
ok( -d "t/unpacked/Acme-Colour" );
ok( -d "t/unpacked/GraphViz" );

my @files = <t/unpacked/GraphViz/*>;
is( scalar(@files), 7 );
