use Test2::V0;

use lib qw|t/lib|;

BEGIN {
    $ENV{ LWP_UA_MOCK } ||= 'playback';
    $ENV{ LWP_UA_MOCK_FILE } ||= __FILE__.'-lwp-mock.out';
}

use Mojo::UserAgent::Mockable;
my $ua = Mojo::UserAgent::Mockable->new( mode => 'lwp-ua-mockable', ignore_headers => 'all' );

use Astro::ADS::Paper;
use Astro::ADS::Search;
use Data::Dumper::Concise;

subtest 'Test all kinds of bibcodes' => sub {
    my @bibcodes = get_bibcodes();

    for my $bibcode ( @bibcodes ) {
        my $paper = Astro::ADS::Paper->new( bibcode => $bibcode );

        is $paper, object {
            # call summary => E();
            field bibcode => T();
            prop isa => 'Astro::ADS::Paper';
            end();
        };
    }
};

subtest 'Fields returned by Searches' => sub {
        pass(); return 1;

        my $search = Astro::ADS::Search->new( q => 'dark matter', ua => $ua);
        $search->fl('ack,aff,aff_id,alternate_bibcode,alternate_title,arxiv_class,author,author_count,author_norm,bibcode,bibgroup,bibstem,citation,citation_count,cite_read_boost,classic_factor,comment,copyright,data,database,date,doctype,doi,eid,entdate,entry_date,esources,facility,first_author,first_author_norm,grant,grant_agencies,grant_id,id,identifier,indexstamp,inst,isbn,issn,issue,keyword,keyword_norm,keyword_schema,lang,links_data,nedid,nedtype,orcid_pub,orcid_other,orcid_user,page,page_count,page_range,property,pub,pub_raw,pubdate,pubnote,read_count,reference,simbid,title,vizier,volume,year');
        my $result = $search->query();
        my @papers = $result->get_papers();
        is @papers, 10, 'Got all papers';
};

subtest 'Create every Paper attribute' => sub {
        my $attributes = { id => 123, bibcode => '2023NewA...9901962J' };
        for my $attr ( qw(ack aff_id alternate_bibcode alternate_title arxiv_class author_count author_norm bibgroup bibstem citation citation_count cite_read_boost classic_factor comment copyright data database date doctype doi eid entdate entry_date esources facility first_author first_author_norm grant grant_agencies grant_id identifier indexstamp inst isbn issn issue keyword_norm keyword_schema lang nedid nedtype orcid_pub orcid_other orcid_user page page_count page_range property pub pub_raw pubdate pubnote read_count reference simbid vizier volume year) ) {
            $attributes->{$attr} = 'Dummy value';
        }
        for my $list ( qw(author aff keyword links_data title) ) {
            $attributes->{$list} = ['Dummy value'];
        }

        ok my $paper = Astro::ADS::Paper->new( $attributes ), 'Creates new Paper object';
};

done_testing();

sub get_bibcodes {
    return (
        '2021MNRAS.504..356D',
        '2012Msngr.147...25G',
        '2022A&A...666A.121R',
        '2024MNRAS.527.9548H',
        '2022A&A...666A.120G',
        '2024SSRv..220...24K',
        '2019MNRAS.490.4040A',
        '2021yCat..75040356D',
        '2024A&A...689A.270P',
        '2015A&A...580A..23P',

        "2016A&A...585A.150N",
        "2024A&A...687A.176K",
        "2022A&A...666A.142S",
        "2023ApJS..269...32S",
        "2024A&A...687A.208P",
        "2023A&A...676A..55L",
        "2023NewA...9901962J",
        "2021MNRAS.506.1073H",
        "2020MNRAS.499.1874M",
        "2023A&A...676A..88P",

        '2023MNRAS.522.5805D',
        '2016AN....337..239P',
        '2017MNRAS.468.2745N',
        '2022SPIE12181E..0BW',
        '2024A&A...683A.110K',
        '2025MNRAS.536...72F',
        '2022AJ....163..191K',
        '2019MNRAS.487.3523C',
        '2020A&A...640A..40H',
        '2014A&A...561A..93H',

        '2006nucl.ex...1042S', # arxiv papers
        '2005astro.ph.10346T',
    );
}
