#!/usr/bin/env perl
use strict;

use Cwd;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::More tests => 7;

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

require App::Followme::ConfiguredObject;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir;
chdir $test_dir;
$test_dir = cwd();

#----------------------------------------------------------------------
# Test simple object creation

do {
    my $top_dir = $test_dir;
    my $base_dir = catfile($test_dir, 'subdir');
    my %configuration = (
                         quick_update => 1,
                         base_directory => $base_dir,
                         top_directory => $top_dir,
                         extra => 'foobar',
                    );

    my $co = App::Followme::ConfiguredObject->new(%configuration);

    is($co->{quick_update}, 1, 'Set quick update'); # test 1
    is($co->{base_directory}, $base_dir, 'Set base directory'); # test 2
    is($co->{top_directory}, $top_dir, 'Set top directory'); # test 3
    is($co->{extra}, undef, 'Nothing extra'); # test 4
};

#----------------------------------------------------------------------
# Test compound object creation

do {
    my $top_dir = $test_dir;
    my $base_dir = catfile($test_dir, 'subdir');
    my %configuration = (
                         base_directory => $base_dir,
                         top_directory => $top_dir,
                         '' => {quick_update => 1},
                         'App::Followme::ConfiguredObject' => {quick_update => 2},
                         'App::Followme::Foobar' => {quick_update => 3},
                    );

    my $co = App::Followme::ConfiguredObject->new(%configuration);

    is($co->{base_directory}, $base_dir, 'Set first field'); # test 5
    is($co->{top_directory}, $top_dir, 'Set second field'); # test 6
    is($co->{quick_update}, 2, 'Set segment field'); # test 7
};
