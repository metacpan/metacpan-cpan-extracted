use v5.14;
use AnyEvent::Discord;
use Test::More tests => 2;

my $client = AnyEvent::Discord->new({ token => '', verbose => ($ENV{'AE_D_VERBOSE'} or 0) });
my $version = $client->VERSION;

ok( ($version and length($version) > 0 and $version =~ /\./), 'module has a version' );
is( $client->user_agent, 'Perl-AnyEventDiscord/' . $version, 'default version string intact' );

1;
