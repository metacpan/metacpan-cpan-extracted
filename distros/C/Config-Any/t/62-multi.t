use strict;
use warnings;
no warnings 'once';

use Test::More tests => 3;

use Config::Any;
use Config::Any::YAML;

my $file   = 't/multi/conf.yml';
my @expect = (
    {   name  => 'TestApp',
        Model => { 'Model::Baz' => { qux => 'xyzzy' } }
    },
    {   name2  => 'TestApp2',
        Model2 => { 'Model::Baz2' => { qux2 => 'xyzzy2' } }
    },
);

my @results = eval { Config::Any::YAML->load( $file ); };

SKIP: {
    skip "Can't load multi-stream YAML files", 3 if $@;
    is( @results, 2, '2 documents' );
    is_deeply( \@results, \@expect, 'structures ok' );

    my $return
        = Config::Any->load_files( { use_ext => 1, files => [ $file ] } );
    is_deeply(
        $return,
        [ { $file => \@expect } ],
        'config-any structures ok'
    );
}
