use strict;
use warnings;

use Test::More tests => 27;
BEGIN { use_ok('App::PerlShell::Config') };

#########################

my $config = App::PerlShell::Config->new(
    'key1' => 'value1',
    'key2' => 'value2',
);

ok( defined $config, "new()");

my $ret;

# Gets
is( $config->config('key1'), 'value1', "get key1" );
is( $config->config('key2'), 'value2', "get key2" );
is( $config->config('key3'), undef, "get non-existent" );
$ret = $config->config();
is( $ret->{key1}, 'value1', "get all (key1)" );
is( $ret->{key2}, 'value2', "get all (key2)" );
is( $ret->{key3}, undef , "get all (non-existent)" );

# Sets
is( $config->config('key1','value3'), 'value1', "set key1" );
is( $config->config('key1'=>'value4'), 'value3', "set key1 comma" );
is( $config->config('key1'), 'value4', "set key1 fatcomma" );
is( $config->config('key3'=>'value3'), undef, "set non-existent" );

# Exists
  undef $ret;
  local $SIG{__WARN__} = sub { $ret = $_[0] };
  eval { $config->exists(); };
ok( $ret =~ /^Key required/, "exists no key" );
is( $config->exists('key1'), 1, "exists key1" );
is( $config->exists('key3'), 0, "exists key3 doesn't" );

# Adds
  undef $ret;
  local $SIG{__WARN__} = sub { $ret = $_[0] };
  eval { $config->add(); };
ok( $ret =~ /^Key required/, "add no key" );
  undef $ret;
  local $SIG{__WARN__} = sub { $ret = $_[0] };
  eval { $config->add('key1'); };
ok( $ret =~ /^Key exists/, "add key exists (carp)" );
is( $config->add('key1'), 0, "add key exists (return)" );
is( $config->add('key3'), 1, "add key3 undef" );
is( $config->config('key3'), undef, "add key3 undef (check)" );
is( $config->add('key4','value4'), 1, "add key4 value4" );
is( $config->config('key4'), 'value4', "add key4 value4 (check)" );

# Deletes
  undef $ret;
  local $SIG{__WARN__} = sub { $ret = $_[0] };
  eval { $config->delete(); };
ok( $ret =~ /^Key required/, "delete no key" );
  undef $ret;
  local $SIG{__WARN__} = sub { $ret = $_[0] };
  eval { $config->delete('key5'); };
ok( $ret =~ /^Key doesn't exist/, "delete key doesn't exist (carp)" );
is( $config->delete('key5'), 0, "delete key doesn't exist (return)" );
is( $config->delete('key3'), 1, "delete key3" );
is( $config->config('key3'), undef, "delete key3 (check)" );
