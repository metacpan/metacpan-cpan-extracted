#
#===============================================================================
#
#         FILE:  04-backend-yaml.t
#
#  DESCRIPTION:  tests App::Open::Backend::YAML
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erik@hollensbe.org>
#      COMPANY:
#      VERSION:  1.0
#      CREATED:  06/02/2008 05:33:18 AM PDT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

use constant CLASS => 'App::Open::Backend::YAML';

BEGIN {
    use_ok(CLASS);
}

my $tmp;
my $def_file;

can_ok( CLASS, "new" );
can_ok( CLASS, "lookup_file" );
can_ok( CLASS, "lookup_url" );

if ( -f "$ENV{HOME}/.mimeyaml" ) {
    lives_ok { $tmp = CLASS->new() } "has .mimeyaml, should not die";
    is( $tmp->def_file, "$ENV{HOME}/.mimeyaml" );
}
else {
    throws_ok { $tmp = CLASS->new() } qr/BACKEND_CONFIG_ERROR/;
}

$def_file = "t/resource/backends/yaml/def1.yaml";

lives_ok { $tmp = CLASS->new( [$def_file] ) };

#
# XXX this indirectly tests the %s templating functionality
#
is( $tmp->def_file,      $def_file );
is( $tmp->lookup_file("gz"),  "gunzip %s" );
is( $tmp->lookup_file(".gz"), "gunzip %s" );
ok( !$tmp->lookup_file(".foo") );

lives_ok { $tmp = CLASS->new( [$def_file] ) };
is( $tmp->lookup_url("http"), "echo" );
is( $tmp->lookup_file("http"), "not_a_url" );

$def_file = "t/resource/backends/yaml/bad_def1.yaml";
throws_ok { $tmp = CLASS->new( [$def_file] ) } qr/BACKEND_CONFIG_ERROR/;

$def_file = "t/resource/backends/yaml/bad_def2.yaml";
throws_ok { $tmp = CLASS->new( [$def_file] ) } qr/BACKEND_CONFIG_ERROR/;

$def_file = "t/resource/backends/yaml/bad_def3.yaml";
throws_ok { local $^W = 0; $tmp = CLASS->new( [$def_file] ) } qr/BACKEND_CONFIG_ERROR/;
