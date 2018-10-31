#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 20;
use Test::Deep;

BEGIN {
    use_ok( 'Bundler::MultiGem::Utl::InitConfig' ) || print "Bail out!\n";
}

diag( "Testing Bundler::MultiGem::Utl::InitConfig, Perl $], $^X" );

#  what has to be defined by Bundler::MultiGem::Utl::InitConfig.pm
ok( defined ${Bundler::MultiGem::Utl::InitConfig::DEFAULT_CONFIGURATION}, '$DEFAULT_CONFIGURATION is defined' );
ok( defined &Bundler::MultiGem::Utl::InitConfig::merge_configuration, 'merge_configuration() is defined' );
ok( defined &Bundler::MultiGem::Utl::InitConfig::default_main_module, 'default_main_module() is defined' );
ok( defined &ruby_constantize, 'ruby_constantize() is defined' );

# DEFAULT_CONFIGURATION context
{
  my $config = ${Bundler::MultiGem::Utl::InitConfig::DEFAULT_CONFIGURATION};
  is_deeply(
  	[sort keys %$config], [qw(cache directories gem)], 'keys of $DEFAULT_CONFIGURATION'
  );

  my $gem_config = $config->{gem};
  is_deeply($gem_config->{source}, "https://rubygems.org", 'DEFAULT_CONFIGURATION->gem->name undef');
  ok(! defined $gem_config->{name}, 'DEFAULT_CONFIGURATION->gem->name undef');
  ok(! defined $gem_config->{main_module}, 'DEFAULT_CONFIGURATION->gem->main_module undef');
  is_deeply(
  	$gem_config->{versions}, [()], 'DEFAULT_CONFIGURATION->gem->versions empty'
  );
}

# merge_configuration context
{
  my $custom_config = {
  	'gem' => {
	  'name' => 'jsonschema_serializer',
  	  'versions' => [qw(0.0.5 0.1.0)]
  	}
  };
  my $actual = Bundler::MultiGem::Utl::InitConfig::merge_configuration($custom_config);

  my $gem_config = $actual->{gem};
  is_deeply($gem_config->{source}, "https://rubygems.org", 'merge_configuration: gem->source');
  is_deeply($gem_config->{name}, "jsonschema_serializer", 'merge_configuration: gem->name');
  is_deeply($gem_config->{main_module}, "JsonschemaSerializer", 'merge_configuration: gem->main_module');
  is_deeply(
  	$gem_config->{versions}, [qw(0.0.5 0.1.0)], 'merge_configuration: gem->versions'
  );
}

# default_main_module context
{
  my $f = \&Bundler::MultiGem::Utl::InitConfig::default_main_module;
  my $main_module_test = sub {
  	$f->(shift)->{gem}->{main_module};
  };

  my $missing_config = {
    'gem' => {
      'name' => 'jsonschema_serializer',
      'versions' => [qw(0.0.5 0.1.0)]
    }
  };
  my $provided_config = {
    'gem' => {
      'name' => 'rspec',
      'main_module' => 'RSpec',
      'versions' => [qw(0.0.5 0.1.0)]
    }
  };
  is_deeply($main_module_test->($missing_config), "JsonschemaSerializer", 'default_main_module: main_module not provided');
  is_deeply($main_module_test->($provided_config), "RSpec", 'default_main_module: main_module provided');
}

# ruby_constantize context
{
  is_deeply(ruby_constantize('rails'), 'Rails', 'ruby_constantize: rails');
  is_deeply(ruby_constantize('jsonschema_serializer'), 'JsonschemaSerializer', 'ruby_constantize: jsonschema_serializer');
  is_deeply(ruby_constantize('foo-bar'), 'Foo::Bar', 'ruby_constantize: foo-bar');
  is_deeply(ruby_constantize('foo-bar_baz'), 'Foo::BarBaz', 'ruby_constantize: foo-bar_baz');
}