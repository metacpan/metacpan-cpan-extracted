use Test2::V0;

use lib qw|t/lib|;

BEGIN {
    $ENV{ LWP_UA_MOCK } ||= 'playback';
    $ENV{ LWP_UA_MOCK_FILE } ||= __FILE__.'-lwp-mock.out';
}

use Mojo::UserAgent::Mockable;
my $ua = Mojo::UserAgent::Mockable->new( mode => 'lwp-ua-mockable', ignore_headers => 'all' );

use Astro::ADS::Search;
use Data::Dumper::Concise;

subtest 'Bad Key error in Result' => sub {
    local $ENV{ADS_DEV_KEY} = 'BAD_TOKEN';
    my $search = Astro::ADS::Search->new( q => 'dark matter', fl => 'author,keyword', rows => 100, ua => $ua);

    my $result;
    my $expected_error = 'UNAUTHORIZED';
    like(
        warnings { $result = $search->query() }, # DEBUG = 0
        [qr/HTTP Error: $expected_error/],       # my error message
        #warnings { $result = $search->query() },
        #[
            #qr{^GET /v1/search/query.+Authorization: Bearer BAD_TOKEN}s, # DEBUG request
            #qr/HTTP Error: $expected_error/,
        #],
        'Caught dev token error'
    ) or warn "\n#### Is \$Astro::ADS::DEBUG set to the expected value? ####\n\n";

    is $result, object {
        prop isa    => 'Astro::ADS::Result';
        field error => $expected_error;
        field docs  => [];
        end();
    }, 'Result contains the error message';

    like(
        warning { $result->rows() },
        qr/^Empty Result object: $expected_error/,  # my error message
        'Sensible warning when acting on a Result with an error'
    );
};

=pod Can't seem to engineer a timeout

subtest 'Connection timeout' => sub {
        $ua->connect_timeout(1);
        my $search = Astro::ADS::Search->new( q => 'dark energy', sort => 'citation_count desc', rows => 100, ua => $ua);
        $search->fl('ack,aff,aff_id,alternate_bibcode,alternate_title,arxiv_class,author,author_count,author_norm,bibcode,bibgroup,bibstem,citation,citation_count,cite_read_boost,classic_factor,comment,copyright,data,database,date,doctype,doi,eid,entdate,entry_date,esources,facility,first_author,first_author_norm,grant,grant_agencies,grant_id,id,identifier,indexstamp,inst,isbn,issn,issue,keyword,keyword_norm,keyword_schema,lang,links_data,nedid,nedtype,orcid_pub,orcid_other,orcid_user,page,page_count,page_range,property,pub,pub_raw,pubdate,pubnote,read_count,reference,simbid,title,vizier,volume,year');
        my $result = $search->query();
        $DB::single = 1;
        like $result->error, qr/Timeout/;
};

=cut

done_testing();
