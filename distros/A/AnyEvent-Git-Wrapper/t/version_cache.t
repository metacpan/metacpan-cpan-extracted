use strict;
use warnings;
use Test::More tests => 8;
BEGIN { $^O eq 'MSWin32' ? eval q{ use Event; 1 } || q{ use EV } : eval q{ use EV } }
use AnyEvent::Git::Wrapper;
use File::Temp qw( tempdir );
use AnyEvent;

my $count = 0;
do {
  my $old;
  my $new;
  $old = \&AnyEvent::Git::Wrapper::RUN;
  $new = sub { $count++; goto $old; };
  no warnings 'redefine';
  *AnyEvent::Git::Wrapper::RUN = $new;
};

foreach my $i (0..1)
{
  $count = 0;
  my $git = AnyEvent::Git::Wrapper->new(tempdir(CLEANUP => 1), cache_version => 1);

  my $version = $i ? $git->version : $git->version(AE::cv)->recv;

  ok $version, "version = $version";

  is $git->version,               $version, "version still = $version";
  is $git->version(AE::cv)->recv, $version, "version still = $version (non blocking)";
  is $count, 1, 'count = 1';
}
