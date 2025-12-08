#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

# --- 1. Define our Mock Plugins FIRST ---
# We define them in the 'main' namespace *before* %INC
# is manipulated.
{

  package Config::Resolver::Plugin::Mocky;

  our $PROTOCOL = 'mock_proto';  # The new contract

  # "Spy" constructor
  sub new {
    my ( $class, $options ) = @_;
    return bless { _received_options => $options }, $class;
  }
  sub init                 { return $PROTOCOL; }
  sub get_received_options { $_[0]->{_received_options} }
}
{

  package Config::Resolver::Plugin::Busted;
  # This plugin is missing 'our $PROTOCOL'
  sub new  { bless {}, shift; }
  sub init { return 'busted'; }
}

# --- 2. The "Magic" Hack ---
# We manually "trick" Perl's %INC hash.
# This tells Module::Load that these files are *already* loaded
# and that they were loaded from *this* file (__FILE__).
$INC{'Config/Resolver/Plugin/Mocky.pm'}  = __FILE__;
$INC{'Config/Resolver/Plugin/Busted.pm'} = __FILE__;

# --- 3. Now, load the modules for testing ---
# We load Config::Resolver *after* the mocks are defined and
# %INC is populated.
use Test::More;
use Config::Resolver;
use Data::Dumper;

# --- Test 1: Test the correct path ---
subtest 'Test Case: Engine - Plugin config is correctly passed' => sub {

  # 1. This is the global config for the *engine*
  my $global_options = {
    debug         => 1,
    warning_level => 'warn',
    logger        => undef,
  };

  # 2. This is the *full* config hash for *all* plugins
  my $plugin_config = {
    'mock_proto' => { 'host' => 'merlin.example.com' },  # Keyed by $PROTOCOL
    'other_key'  => { 'foo'  => 'bar' },
  };

  # 3. This is what we *expect* our plugin's new() to receive
  my $expected_options_for_plugin = { %{$global_options}, %{ $plugin_config->{'mock_proto'} }, };

  # 4. Run the test
  my $resolver = Config::Resolver->new(
    { plugins       => ['Mocky'],      # Pass the *Plugin Name*
      plugin_config => $plugin_config,
      %{$global_options}
    }
  );

  # 5. Verify the results
  my $handlers = $resolver->get_handler_map;

  ok( $handlers->{'mock_proto'}, 'Plugin successfully registered its protocol' );

  my $plugin_obj = $handlers->{'mock_proto'};
  isa_ok( $plugin_obj, 'Config::Resolver::Plugin::Mocky' );

  # This is the "Hallelujah" check:
  is_deeply( $plugin_obj->get_received_options,
    $expected_options_for_plugin, 'Plugin new() received the correctly merged config hash' );
};

# --- Test 2: Test the "Busted" path (missing $PROTOCOL) ---
subtest 'Test Case: Engine - Plugin croaks if $PROTOCOL is missing' => sub {

  # The 'dies' test passes if the code inside it 'croak's
  eval { my $resolver = Config::Resolver->new( { plugins => ['Busted'] } ); };

  like( $@, qr/Plugin .* must define a package variable '\$PROTOCOL'/, 'Correctly croaks when plugin is missing $PROTOCOL' );
};

done_testing();

1;
