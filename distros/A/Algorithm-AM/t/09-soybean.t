# test exact result statistics (issue #42)
use strict;
use warnings;
use Algorithm::AM;
use Test::More 0.88;
plan tests => 6;
use Test::NoWarnings;

use FindBin qw($Bin);
use Path::Tiny;
my $dataset = dataset_from_file(
    path => path($Bin, 'data', 'issue42.txt'),
    format => 'commas',
    unknown => '?',
);
my $am = Algorithm::AM->new(
    training_set => $dataset,
    exclude_given => 1,
    exclude_nulls => 1);
my $test_item = $dataset->get_item(0);
my $result = $am->classify($test_item);

my $score = $result->scores->{'purple-seed-stain'};
ok($score == 327680, 'correct score for purple-seed-stain');
ok($score == $result->total_points, 'purple-seed-stain has all points');
my $set = $result->analogical_set;

ok(scalar keys %$set == 2, 'two items in analogical set');
ok($set->{c}->{score} == 278528, 'score for c') or note $set->{c}->{score};
ok($set->{b}->{score} == 49152, 'score for b') or note $set->{b}->{score};
