use Test::More;
use strict;
use warnings;

use File::Basename;
use File::Spec;

use Dancer2::Plugin::LiteBlog::Activities;

my $activities;

my $localdir = File::Spec->catfile(dirname(__FILE__), 'doesnotexist');
eval { $activities = Dancer2::Plugin::LiteBlog::Activities->new( 
    root => $localdir, source => 'activities.yml') };
like ($@, qr/Not a valid dir/, "Unable to create without a valid root");

$localdir = File::Spec->catfile(dirname(__FILE__), 'public');
eval { $activities = Dancer2::Plugin::LiteBlog::Activities->new( 
    root => $localdir, source => 'doesnotexist.yml') };
is ($@, '', "Activities created with a valid root");

eval { $activities->elements};
like $@, qr/Missing file:/, "The activities file must be present";

$activities = Dancer2::Plugin::LiteBlog::Activities->new( 
    root => dirname($localdir), source => 'activities.yml');
eval { $activities->elements };
is $@, '', "With a valid activities.yml file, it works";

is (scalar(@{ $activities->elements }), 2, "activities has 2 elements");
is $activities->elements->[1]->{'name'}, 'GitHub', "Second activity is GitHub";

done_testing;

