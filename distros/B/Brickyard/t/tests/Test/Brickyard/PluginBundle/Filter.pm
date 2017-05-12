use 5.010;
use strict;
use warnings;

package Test::Brickyard::PluginBundle::Filter;

# ABSTRACT: Class tests for Brickyard::PluginBundle::Filter
use Test::Most;
use Brickyard;
use parent 'Test::MyBase';
sub class { 'Brickyard::PluginBundle::Filter' }

sub original_bundle_config {
    [   [   '@SomeBundle/Some::Thing',
            'Some::Thing',
            {   'baz' => [ '43', 'blah' ],
                'foo' => 'bar'
            }
        ],
        [ '@SomeBundle/Other::Thing', 'Other::Thing', {} ]
    ];
}

sub remove_from_config : Test(2) {
    my $test = shift;

    # need a brickyard so remove_from_config() can indirectly call
    # expand_package().
    my $obj =
      $test->make_object(brickyard => Brickyard->new(base_package => 'Foobar'));
    my $bundle_config = $test->original_bundle_config;
    $obj->remove_from_config($bundle_config, [qw(Foobar)]);
    eq_or_diff $bundle_config, $test->original_bundle_config,
      'remove nonexistent plugin';
    $obj->remove_from_config($bundle_config, [qw(Some::Thing)]);
    eq_or_diff $bundle_config,
      [ [ '@SomeBundle/Other::Thing', 'Other::Thing', {} ] ],
      'remove [Some::Thing]';
}
1;
