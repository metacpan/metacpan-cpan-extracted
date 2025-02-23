use Test2::V0;
use Test2::Tools::Compare qw(number_gt);

use lib qw|t/lib|;

BEGIN {
    $ENV{ LWP_UA_MOCK } ||= 'playback';
    $ENV{ LWP_UA_MOCK_FILE } ||= __FILE__.'-lwp-mock.out';
}

use Astro::ADS::Search;
use Data::Dumper::Concise;
use Mojo::UserAgent::Mockable;

my $ua = Mojo::UserAgent::Mockable->new( mode => 'lwp-ua-mockable', ignore_headers => 'all' );

my $ads = Astro::ADS::Search->new( q => 'star', fl => 'bibcode', ua => $ua );

subtest 'Search object ok' => sub {
    is $ads, object {
        prop isa => 'Astro::ADS::Search';

        field q  => 'star';
        field fl => 'bibcode';
        field ua => E();

        field base_url => check_isa('Mojo::URL');

        field authors => [];
        field objects => [];
        field bibcode => [];
        field author_logic => {};
        field object_logic => {};

        end();
    };
};

subtest query => sub {
    ok my $result = $ads->query(), 'Test Search';
    is $result, check_isa( 'Astro::ADS::Result' );
    is $result, object {
        prop isa => 'Astro::ADS::Result';

        field q  => 'star';
        field fl => 'bibcode';

        field rows => 10;
        field start => 0;
        field numFound => number_gt 645000;
        field numFoundExact => T();
        field docs => array { 
            item 9 => check_isa('Astro::ADS::Paper');
            end();
        };

        end();
    };
};

subtest 'Search with new terms' => sub {
    my $result = $ads->query( {q => 'dark energy'} );
    is $result->q, 'dark energy', 'Search on new term';

    is $ads->q, 'star', 'New query leaves old object unchanged';
};

subtest 'Additional term to current Search' => sub {
    my $result = $ads->query( {'+q' => 'neutron'} );
    is $result->q, 'star neutron', 'Adds neutron to star search';
};

subtest 'Search terms' => sub {
# should use separate search to avoid action at a distance
    is $ads->gather_search_terms,
        hash {
            field q => 'star';
            field fl => 'bibcode';
            end();
        },
        'Search terms from constructor';

    ok $ads->authors( ['Paunzen, E', 'Iliev, I K'] );
    is $ads->authors, ['Paunzen, E', 'Iliev, I K'], 'Sets Author list';
    ok $ads->objects( ['Lambda Bootis'] );
    is $ads->objects, ['Lambda Bootis'], 'Sets Object list';
    ok $ads->rows(20);

    is $ads->gather_search_terms,
        hash {
            field q => q{star author:("Paunzen, E" "Iliev, I K") object:"Lambda Bootis"};
            field fl => 'bibcode';
            field rows => 20;
            end();
        },
        'Building Search terms from accessors';
};

done_testing();
