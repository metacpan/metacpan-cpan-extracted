use File::Temp;
use Test::More tests => 11;

# Set up an end block to clear the cache when we exit.
END
{
  # Clean up our cache
  Cache::SizeAwareFileCache::Clear($CGI::Cache::CACHE_PATH)
    if defined $Cache::SizeAwareFileCache::VERSION;
  # To prevent a warning
  $CGI::Cache::CACHE_PATH .= '';
}

use strict;
use File::Path;
use vars qw( $VERSION );

$VERSION = sprintf "%d.%02d%02d", q/0.10.0/ =~ /(\d+)/g;

my $TEMPDIR = File::Temp::tempdir();

# ----------------------------------------------------------------------------

# Test 1: that the module can be loaded without errors
BEGIN{ use_ok 'CGI::Cache' }

# ----------------------------------------------------------------------------

# Tests 2,3: that we can initialize the cache with the default values
{
  my $x;
  $@ = '';

  eval {
    $x = CGI::Cache::setup();
  };

  is($@,'','No errors initializing with default values');
  ok($x,'Return value after initializing with default values');

  Cache::SizeAwareFileCache::Clear($CGI::Cache::CACHE_PATH);
}

# ----------------------------------------------------------------------------

# Tests 4,5: that we can initialize the cache with the non-default values
{
  my $x;
  $@ = '';

  eval {
    $x = CGI::Cache::setup( { cache_options =>
                              { cache_root => $TEMPDIR,
                                namespace => $0,
                                username => '',
                                filemode => 0666,
                                max_size => 20 * 1024 * 1024,
                                expires_in => 6 * 60 * 60,
                              }
                            } );
  };

  is($@,'','No errors initializing with non-default values');
  ok($x,'Return value after initializing with non-default values');
}

# ----------------------------------------------------------------------------

# Tests 6,7: that we can set a simple key
{
  my $x;
  $@ = '';

  eval {
    $x = CGI::Cache::set_key( 'test1' );
  };

  is($@,'','No errors setting a simple key');
  ok($x,'Return value after setting a simple key');
}

# ----------------------------------------------------------------------------

# Tests 8,9: that we can set a complex key
{
  my $x;
  $@ = '';

  eval {
    $x = CGI::Cache::set_key( { 'a' => [0,1,2], 'b' => 'test2'} );
  };

  is($@,'','No errors setting a complex key');
  ok($x,'Return value after setting a complex key');
}

# ----------------------------------------------------------------------------

# Test 10: There should be nothing in the cache directory until we actually cache something
ok(!defined(<$TEMPDIR/*>), 'Empty cache directory until something cached');

# ----------------------------------------------------------------------------

CGI::Cache::start();
print "Cached output\n";
CGI::Cache::stop();

# Test 11: There should be a cache directory after we actually cache something
ok(-d $TEMPDIR, 'Cache directory after something cached');

# ----------------------------------------------------------------------------

# Clean up
rmtree $TEMPDIR;

