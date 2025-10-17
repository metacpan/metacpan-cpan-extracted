use Test2::V0;
use Test2::Tools::Compare qw(number_gt);

use lib qw|t/lib|;
use Test::Astro::ADS;

BEGIN {
    $ENV{ LWP_UA_MOCK } ||= 'playback';
    $ENV{ LWP_UA_MOCK_FILE } ||= __FILE__.'-lwp-mock.out';
}

use Astro::ADS::Search;
use Data::Dumper::Concise;
use Mojo::UserAgent::Mockable;

my $ua = Mojo::UserAgent::Mockable->new( mode => 'lwp-ua-mockable', ignore_headers => 'all' );

my $ads = Astro::ADS::Search->new( q => 'author:Paunzen', fl => 'bibcode', ua => $ua);

subtest query => sub {
    ok my $result = $ads->query(), 'Author Search';

    is $result, object {
        prop isa => 'Astro::ADS::Result';

        field q     => 'author:Paunzen';
        field fl    => 'bibcode';
        field start => 0;
        field rows  => 10;
        field numFound      => number_gt(436);
        field numFoundExact => T();
        field docs => array {
            item 9 => check_isa('Astro::ADS::Paper');
            end();
        };

        end();
    };

    my $next_query = $result->next;
    is $next_query, hash {
        field q     => 'author:Paunzen';
        field fl    => 'bibcode';
        field start => 10;
        # no rows key because we don't send the default value
        end();
    }, 'Next query at correct start point';

    $result = $ads->query( $next_query );
    is $result, object {
        prop isa => 'Astro::ADS::Result';

        field q     => 'author:Paunzen';
        field fl    => 'bibcode';
        field start => 10;
        field rows  => 10;
        field numFound      => number_gt(436);
        field numFoundExact => T();
        field docs => array {
            item 9 => check_isa('Astro::ADS::Paper');
            end();
        };

        end();
    };

    $next_query = $result->next(20);
    is $next_query, hash {
        field q     => 'author:Paunzen';
        field fl    => 'bibcode';
        field start => 20;
        field rows  => 20;
        end();
    }, 'Next 20 rows has correct start point';
};

done_testing();
