use Test2::V0;
use Test2::Tools::Compare qw(number_gt);

use lib qw|t/lib|;
use Test::Astro::ADS;

BEGIN {
    $ENV{ LWP_UA_MOCK } ||= 'playback';
    $ENV{ LWP_UA_MOCK_FILE } ||= __FILE__.'-lwp-mock.out';
}

use Astro::ADS::Metrics;
use Data::Dumper::Concise;
use Mojo::UserAgent::Mockable;

my $ua = Mojo::UserAgent::Mockable->new( mode => 'lwp-ua-mockable', ignore_headers => 'all' );

my $bibcode = '2019MNRAS.487.3523C';
my $metrics = Astro::ADS::Metrics->new( bibcode => $bibcode, ua => $ua );

subtest 'Metrics object ok' => sub {
    is $metrics, object {
        prop isa => 'Astro::ADS::Metrics';

        field bibcode  => '2019MNRAS.487.3523C';
        field bibcodes => [];
        field ua       => E();

        field base_url => check_isa('Mojo::URL');

        end();
    };
};

subtest 'Fetch metrics' => sub {
    ok my $json = $metrics->fetch(), "Fetch metrics for $bibcode";
    is $json, hash {
        field 'basic stats'             => E();
        field 'basic stats refereed'    => E();
        field 'citation stats'          => E();
        field 'citation stats refereed' => E();
        field 'histograms'              => E();
        field 'skipped bibcodes'        => [];

        end();
    }, 'Metrics for single bibcode correct';
};

subtest 'Get basic metrics for multiple bibcodes' => sub {
    ok my $result = $metrics->batch(
        ['2003ApJS..148..175S', '2007ApJS..170..377S'],
        { types => ['basic'] }
    ), 'Batch fetch metrics';

    is $result, hash {
        field 'skipped bibcodes' => [];
        field 'basic stats' => hash {
            field 'number of papers' => 2;
            field 'normalized paper count'      => number_gt 0.1;
            field 'total number of reads'       => number_gt 41887;
            field 'average number of reads'     => number_gt 20943;
            field 'median number of reads'      => number_gt 20943;
            field 'recent number of reads'      => number_gt 173;
            field 'total number of downloads'   => number_gt 16779;
            field 'average number of downloads' => number_gt 8389;
            field 'median number of downloads'  => number_gt 8389;
            field 'recent number of downloads'  => number_gt 66;
            end();
        };
        field 'basic stats refereed' => hash {
            field 'number of papers' => 2;
            field 'normalized paper count'      => number_gt 0.1;
            field 'total number of reads'       => number_gt 41887;
            field 'average number of reads'     => number_gt 20943;
            field 'median number of reads'      => number_gt 20943;
            field 'recent number of reads'      => number_gt 173;
            field 'total number of downloads'   => number_gt 16779;
            field 'average number of downloads' => number_gt 8389;
            field 'median number of downloads'  => number_gt 8389;
            field 'recent number of downloads'  => number_gt 66;
            end();
        };
        end();
    }, 'basic metrics correct' or $result->error;
};

subtest 'Get data for a single histogram for multiple bibcodes' => sub {
    ok my $result = $metrics->batch(
        ['2003ApJS..148..175S', '2007ApJS..170..377S'],
        { types    => ['histograms'], histograms => ['citations'] }
    ), 'Fetch histogram';

    is $result, hash {
        field 'skipped bibcodes' => [];
        field histograms => hash {
            field citations => hash {
                field 'refereed to refereed' => hash {
                    field 2007 => number_ge 1722;
                    all_keys match qr/^(199\d|20\d\d)$/;
                    all_vals match qr/^\d{1,4}$/;
                    etc();
                };
                field 'refereed to nonrefereed' => hash {
                    all_keys match qr/^(199\d|20\d\d)$/;
                    all_vals number 0;
                    etc();
                };
                field 'nonrefereed to refereed' => hash {
                    field 2007 => number_ge 314;
                    all_keys match qr/^(199\d|20\d\d)$/;
                    all_vals match qr/^\d{1,4}$/;
                    etc();
                };
                field 'nonrefereed to nonrefereed' => hash {
                    all_keys match qr/^(199\d|20\d\d)$/;
                    all_vals number 0;
                    etc();
                };
                field 'refereed to refereed normalized' => hash {
                    field 2007 => number_gt 87;
                    all_keys match qr/^(199\d|20\d\d)$/;
                    all_vals number_ge 0;
                    etc();
                };
                field 'refereed to nonrefereed normalized' => hash {
                    all_keys match qr/^(199\d|20\d\d)$/;
                    all_vals number 0;
                    etc();
                };
                field 'nonrefereed to refereed normalized' => hash {
                    field 2007 => number_gt 15;
                    all_keys match qr/^(199\d|20\d\d)$/;
                    all_vals number_ge 0;
                    etc();
                };
                field 'nonrefereed to nonrefereed normalized' => hash {
                    all_keys match qr/^(199\d|20\d\d)$/;
                    all_vals number 0;
                    etc();
                };
            };
            end();
        };
        end();
    }, 'histogram correct';
};

subtest 'Get detailed metrics for multiple bibcodes' => sub {
    my @bibcodes = qw(2003ApJS..148..175S 2007ApJS..170..377S);
    ok my $result = $metrics->details( @bibcodes ), 'Fetch details';

    is $result, hash {
        field 'skipped bibcodes' => [];
        field '2003ApJS..148..175S' => hash {
            field citations     => E();
            field downloads     => E();
            field reads         => E();
            field ref_citations => E();
            end();
        };
        field '2007ApJS..170..377S' => hash {
            field citations => hash {
                all_keys match qr/^\d{4}$/;
                all_vals number_ge 0;
                etc();
            };
            field downloads => hash {
                all_keys match qr/^\d{4}$/;
                all_vals number_ge 0;
                etc();
            };
            field reads => hash {
                all_keys match qr/^\d{4}$/;
                all_vals number_ge 0;
                etc();
            };
            field ref_citations => hash {
                all_keys match qr/^\d{4}$/;
                all_vals number_ge 0;
                etc();
            };
            end();
        };
        end();
    }, 'Details correct';
};

done_testing();
