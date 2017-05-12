use 5.010;
use strict;
use warnings;

package Test::Brickyard;

# ABSTRACT: Class tests for Brickyard
use Test::Most;
use Test::Fatal;
use Brickyard;
use parent 'Test::MyBase';
sub class { 'Brickyard' }

sub constructor : Test(2) {
    my $test = shift;
    my $obj  = $test->make_object;
    isa_ok $obj, $test->class;
    is $obj->base_package, 'MyApp', 'default base_package';
}

sub set_base_package : Test(1) {
    my $test = shift;
    my $obj = $test->make_object(base_package => 'Foobar');
    is $obj->base_package, 'Foobar', 'set base_package on constructor';
}

sub expand_package : Tests {
    my $test = shift;
    my $obj  = $test->make_object;
    is $obj->expand_package('@Service::Default'),
      'MyApp::PluginBundle::Service::Default',
      'expand [@Default]';
    is $obj->expand_package('*@Filter'), 'Brickyard::PluginBundle::Filter',
      'expand [*@Filter]';
    is $obj->expand_package('*Filter'), 'Brickyard::Plugin::Filter',
      'expand [*Filter]';
    is $obj->expand_package('=Foo::Bar'), 'Foo::Bar', 'expand [=Foo::Bar]';
    is $obj->expand_package('@=Foo::Bar'), 'MyApp::Plugin::@=Foo::Bar',
      'expand [@=Foo::Bar] does not recognize @= as either @ or =';
    is $obj->expand_package('Some::Thing'), 'MyApp::Plugin::Some::Thing',
      'expand [Some::Thing]';
    is $obj->expand_package('-Thing::Frobnulizer'),
      'MyApp::Role::Thing::Frobnulizer', 'expand [-Thing::Frobnulizer]';

    # custom expansions
    is $obj->expand_package('%Foo::Bar'),
      'MyApp::Plugin::%Foo::Bar', 'expand [%Foo::Bar] without custom expansion';
    $obj->expand([ 's/^%/MyOtherApp::Plugin::/' ]);
    is $obj->expand_package('%Foo::Bar'),
      'MyOtherApp::Plugin::Foo::Bar', 'expand [%Foo::Bar] with custom expansion';
}

sub parse_ini : Tests {
    my $test = shift;
    my $ini  = <<'EOINI';
; A comment
name = Foobar

[@Default]

[Some::Thing]
foo = bar
baz = 43
baz = blah
EOINI
    my $config = $test->make_object->parse_ini($ini);
    eq_or_diff $config,
      [ [ '_',        '_',        { name => 'Foobar' } ],
        [ '@Default', '@Default', {} ],
        [   'Some::Thing',
            'Some::Thing',
            {   'baz' => [ '43', 'blah' ],
                'foo' => 'bar'
            }
        ]
      ],
      'parsed config';

    # Now with callback
    $config = $test->make_object->parse_ini($ini, sub { uc $_[0] });
    eq_or_diff $config,
      [ [ '_',        '_',        { name => 'FOOBAR' } ],
        [ '@Default', '@Default', {} ],
        [   'Some::Thing',
            'Some::Thing',
            {   'baz' => [ '43', 'BLAH' ],
                'foo' => 'BAR'
            }
        ]
      ],
      'parsed config with callback';
}

sub expand_hash : Tests {
    my $test = shift;

    my $expands_ok = sub {
        my ($flat, $expect, $name) = @_;
        my $got = $test->make_object->_expand_hash($flat);
        is_deeply($got, $expect, $name) or diag explain $got;
    };

    #
    my $flat = {
        'web'    => 'the-foo-web',
        'mailto' => 'the-foo-mailto',
        'url'    => 'the-foo-url'
    };
    $expands_ok->($flat, $flat, 'simple hash');

    #
    $flat = {
        'foo.web'    => 'the-foo-web',
        'bar'        => [ 'the-first-bar', 'the-second-bar' ],
        'foo.mailto' => 'the-foo-mailto',
        'foo.url'    => 'the-foo-url'
    };
    my $expect = {
        foo => {
            web    => 'the-foo-web',
            mailto => 'the-foo-mailto',
            url    => 'the-foo-url'
        },
        'bar' => [ 'the-first-bar', 'the-second-bar' ],
    };
    $expands_ok->($flat, $expect, 'simple subhash');

    #
    $flat = {
        'foo.0.web'    => 'the-foo-web',
        'foo.0.mailto' => 'the-foo-mailto',
        'foo.1.url'    => 'the-foo-url'
    };
    $expect = {
        foo => [
            {   web    => 'the-foo-web',
                mailto => 'the-foo-mailto',
            },
            { url => 'the-foo-url' }
        ],
    };
    $expands_ok->($flat, $expect, 'array of hashes');

    #
    $flat = {
        'foo.0.web.1'  => 'the-second-foo-web',
        'foo.0.mailto' => 'the-foo-mailto',
        'foo.1.url'    => 'the-foo-url',
        'foo.0.web.2'  => 'the-third-foo-web'
    };
    $expect = {
        foo => [
            {   web => [ undef, 'the-second-foo-web', 'the-third-foo-web' ],
                mailto => 'the-foo-mailto',
            },
            { url => 'the-foo-url' }
        ],
    };
    $expands_ok->($flat, $expect, '... now with possible sub-arrays');

    #
    $flat = {
        'foo.0.web'  => 'the-foo-web',
        'foo.mailto' => 'the-foo-mailto',
    };
    like exception { $test->make_object->_expand_hash($flat) },
      qr/param clash for foo\.(mailto|0\.web)/, 'param clash';

    #
    $flat = {
        '0.web'    => 'the-foo-web',
        '1.mailto' => 'the-foo-mailto',
        '2.2'      => 'the-weird',
        3          => 'the-three'
    };
    $expect = {
        0 => { web    => 'the-foo-web' },
        1 => { mailto => 'the-foo-mailto' },
        2 => [ undef, undef, 'the-weird' ],
        3 => 'the-three'
    };
    $expands_ok->($flat, $expect, 'numeric keys');
}

1;
