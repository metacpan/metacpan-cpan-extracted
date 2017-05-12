#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More tests => 1;
use File::Copy;

if( $^O =~ m/mswin32/i )
{
  my $tmp = $ENV{TMP} || $ENV{TEMP};
#  ok( copy( 't/sessiontest', "$tmp\\apache2_asp_sessions"  ) );
  ok( copy( 't/sessiontest', "$tmp\\apache2_asp_applications" ) );
}
else
{
#  ok( copy( 't/sessiontest', '/tmp/apache2_asp_sessions' ) );
  unlink( '/tmp/apache2_asp_applications' );
  ok( copy( 't/sessiontest', '/tmp/apache2_asp_applications' ) );
}# end if()

# Also clear the cache:
my $dir = 't/PAGE_CACHE/DefaultApp';
foreach my $file ( <$dir/*.pm> )
{
  unlink( $file );
}# end foreach()

