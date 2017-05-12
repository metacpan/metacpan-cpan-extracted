use strict;
use warnings;
use Algorithm::FeatureSelection;
use Test::More tests => 2;

my $fs = Algorithm::FeatureSelection->new();
isa_ok( $fs, 'Algorithm::FeatureSelection' );

my $test_features = {
    'blog_A' => { 'Female' => 3 },
    'blog_B' => { 'Female' => 1 },
    'blog_C' => {
        'Female' => 4,
        'Male'   => 3
    },
    'blog_D' => {
        'Female' => 389,
        'Male'   => 913
    },
    'blog_E' => { 'Male' => 1 },
    'blog_F' => { 'Male' => 1 },
    'blog_G' => {
        'Female' => 3,
        'Male'   => 2
    },
    'blog_H' => { 'Female' => 1 },
    'blog_J' => { 'Female' => 2 },
    'blog_I' => {
        'Female' => 4,
        'Male'   => 10
    },
    'blog_K' => { 'Male' => 1 },
    'blog_L' => {
        'Female' => 1,
        'Male'   => 3
    },
    'blog_N' => { 'Male' => 1 },
    'blog_M' => { 'Male' => 1 },
    'blog_P' => { 'Male' => 1 },
    'blog_O' => {
        'Female' => 7,
        'Male'   => 15
    },
    'blog_Q' => { 'Male'   => 2 },
    'blog_R' => { 'Female' => 1 },
    'blog_S' => { 'Female' => 4 },
    'blog_T' => {
        'Female' => 18,
        'Male'   => 1
    },
    'blog_U' => { 'Male' => 1 },
};

my $correct_pmi = {
    'blog_A' => { 'Female' => '1.6702' },
    'blog_B' => { 'Female' => '1.6702' },
    'blog_C' => {
        'Female' => '0.8629',
        'Male'   => '-0.6782'
    },
    'blog_D' => {
        'Female' => '-0.0727',
        'Male'   => '0.0321'
    },
    'blog_E' => { 'Male' => '0.5441' },
    'blog_F' => { 'Male' => '0.5441' },
    'blog_G' => {
        'Female' => '0.9333',
        'Male'   => '-0.7778'
    },
    'blog_H' => { 'Female' => '1.6702' },
    'blog_I' => {
        'Female' => '-0.1371',
        'Male'   => '0.0587'
    },
    'blog_J' => { 'Female' => '1.6702' },
    'blog_K' => { 'Male'   => '0.5441' },
    'blog_L' => {
        'Female' => '-0.3298',
        'Male'   => '0.1291'
    },
    'blog_M' => { 'Male' => '0.5441' },
    'blog_N' => { 'Male' => '0.5441' },
    'blog_O' => {
        'Female' => '0.0182',
        'Male'   => '-0.0084'
    },
    'blog_P' => { 'Male'   => '0.5441' },
    'blog_Q' => { 'Male'   => '0.5441' },
    'blog_R' => { 'Female' => '1.6702' },
    'blog_S' => { 'Female' => '1.6702' },
    'blog_T' => {
        'Female' => '1.5922',
        'Male'   => '-3.7038'
    },
    'blog_U' => { 'Male' => '0.5441' }
};

my $pmi = $fs->pairwise_mutual_information($test_features);

for my $f ( keys %$pmi ) {
    for my $c ( keys %{ $pmi->{$f} } ) {
        $pmi->{$f}->{$c} = sprintf( "%6.4f", $pmi->{$f}->{$c} );
    }
}

is_deeply( $pmi, $correct_pmi );
