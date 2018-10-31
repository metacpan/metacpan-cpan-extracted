#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 18;
use Test::Deep;
use Test::Exception;

BEGIN {
    use_ok( 'Bundler::MultiGem::Model::Gem' ) || print "Bail out!\n";
}

diag( "Testing Bundler::MultiGem::Model::Gem, Perl $], $^X" );

ok( defined &gem_vname, 'gem_vname() is defined' );
ok( defined &gem_vmodule_name, 'gem_vmodule_name() is defined' );
ok( defined &norm_v, 'norm_v() is defined' );

# Context gem_vname
{
  is_deeply(gem_vname("jsonschema_serializer", "0.1.0"), "v010-jsonschema_serializer", "gem_vname()")
}

# Context gem_vmodule_name
{
   is_deeply(gem_vmodule_name("JsonschemaSerializer", "0.1.0"), "V010::JsonschemaSerializer", "gem_vmodule_name()");
   is_deeply(gem_vmodule_name("Rails", "6.0.0-preview"), "V600::Preview::Rails", "gem_vmodule_name() complex");
}

# Context norm_v
{
  is_deeply(norm_v("0.1.0"), "v010", "norm_v() 0.1.0");
  is_deeply(norm_v("6.0.0-preview"), "v600-preview", "norm_v() 6.0.0-preview");
}

# Context a gem instance

{
  my $config = {
  	main_module => "JsonschemaSerializer",
    name => "jsonschema_serializer",
    source => "https://rubygems.org",
    versions => [qw(0.0.5 0.1.0)],
  };

  my $gem = Bundler::MultiGem::Model::Gem->new($config);
  is_deeply($gem->config, $config, "config() getter");
  is_deeply($gem->name, "jsonschema_serializer", "name() getter");
  is_deeply($gem->source, "https://rubygems.org", "source() getter");
  is_deeply($gem->main_module, "JsonschemaSerializer", "main_module() getter");
  is_deeply($gem->versions, [qw(0.0.5 0.1.0)], "versions() getter");

  is_deeply($gem->vname("0.0.5"), "v005-jsonschema_serializer", "vname() getter");
  dies_ok { $gem->vname } 'vname() dies without an $v arg';
  is_deeply($gem->vmodule_name("0.0.5"), "V005::JsonschemaSerializer", "vmodule_name() getter");
  dies_ok { $gem->vmodule_name } 'vmodule_name() dies without an $v arg';
}