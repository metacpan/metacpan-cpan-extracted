package MockApp;
use strict;
use warnings;
no warnings 'once';

use Test::More tests => 6*9;
use Scalar::Util qw(blessed reftype);
use Config::Any;
use Config::Any::General;
use Config::Any::INI;
use Config::Any::JSON;
use Config::Any::Perl;
use Config::Any::XML;
use Config::Any::YAML;

our %ext_map = (
    conf => 'Config::Any::General',
    ini  => 'Config::Any::INI',
    json => 'Config::Any::JSON',
    pl   => 'Config::Any::Perl',
    xml  => 'Config::Any::XML',
    yml  => 'Config::Any::YAML'
);

sub load_parser_for {
    my $f = shift;
    return unless $f;

    my ( $ext ) = $f =~ m{ \. ( [^\.]+ ) \z }xms;
    my $mod = $ext_map{ $ext };
    return !$mod->is_supported ? ( 1, $mod ) : ( 0, $mod );
}

for my $f ( map { "t/conf/conf.$_" } keys %ext_map ) {
    my ( $skip, $mod ) = load_parser_for( $f );
    SKIP: {
        skip "File loading backend for $mod not found", 9
            if $skip && !$ENV{RELEASE_TESTING};

        ok( my $c_arr
                = Config::Any->load_files(
                { files => [ $f ], use_ext => 1 } ),
            "load_files with use_ext works [$f]"
        );
        ok( my $c = $c_arr->[ 0 ], "load_files returns an arrayref" );

        ok( ref $c, "load_files arrayref contains a ref" );
        my $ref = blessed $c ? reftype $c : ref $c;
        is( substr( $ref, 0, 4 ), "HASH", "hashref" );

        my ( $name, $cfg ) = each %$c;
        is( $name, $f, "filename matches" );

        my $cfgref = blessed $cfg ? reftype $cfg : ref $cfg;
        is( substr( $cfgref, 0, 4 ), "HASH", "hashref cfg" );

        is( $cfg->{ name }, 'TestApp', "appname parses" );
        is( $cfg->{ Component }{ "Controller::Foo" }->{ foo },
            'bar', "component->cntrlr->foo = bar" );
        is( $cfg->{ Model }{ "Model::Baz" }->{ qux },
            'xyzzy', "model->model::baz->qux = xyzzy" );
    }
}

