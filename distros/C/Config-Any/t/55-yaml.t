use strict;
use warnings;
no warnings 'once';

use Test::More;
use Config::Any;
use Config::Any::YAML;
use Data::Dumper;

sub _dump {
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Indent = 1;
  my $out = Data::Dumper::Dumper(@_);
  $out =~ s/\s*\z//;
  $out eq 'undef' ? undef : $out;
}

if ( !Config::Any::YAML->is_supported && !$ENV{RELEASE_TESTING} ) {
    plan skip_all => 'YAML format not supported';
}
else {
    plan tests => 6;
}

{
    my $config = Config::Any::YAML->load( 't/conf/conf.yml' );
    ok( $config );
    is( $config->{ name }, 'TestApp' );
}

# test invalid config
{
    local $TODO = 'YAML::Syck parses invalid files'
        if $INC{'YAML/Syck.pm'};
    my $file = 't/invalid/conf.yml';
    my $config = eval { Config::Any::YAML->load( $file ) };


    is _dump($config), undef, 'config load failed';
    isnt $@, '', 'error thrown';
}

# parse error generated on invalid config
{
    local $TODO = 'YAML::Syck parses invalid files'
        if $INC{'YAML/Syck.pm'};
    my $file = 't/invalid/conf.yml';
    my $config = eval { Config::Any->load_files( { files => [$file], use_ext => 1} ) };

    is _dump($config), undef, 'config load failed';
    isnt $@, '', 'error thrown';
}
