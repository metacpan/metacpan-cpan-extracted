use strict;
use warnings;
use utf8;

use Class::Unload;
use Data::Validate::Sanctions;
use YAML::XS qw(Dump);
use Path::Tiny qw(tempfile);
use List::Util qw(first);
use Test::More;
use Test::Warnings;
use Test::MockModule;
use Test::Warn;
use Test::MockObject;
use List::Util qw (any);

my %args = (
    eu_url                => "file://t/data/sample_eu.xml",
    ofac_sdn_url          => "file://t/data/sample_ofac_sdn.zip",
    ofac_consolidated_url => "file://t/data/sample_ofac_consolidated.xml",
    hmt_url               => "file://t/data/sample_hmt.csv",
);

my $mocked_ua = Test::MockModule->new('Mojo::UserAgent');
my $calls     = 0;
$mocked_ua->mock(
    get => sub {
        my ($self, $url) = @_;

        $calls++;
        die "User agent MockObject is hit by the url: $url";
    });

subtest 'source url arguments' => sub {
    my %test_args = (
        eu_url                => 'eu.binary.com',
        ofac_sdn_url          => 'ofac_snd.binary.com',
        ofac_consolidated_url => 'ofac_con.binary.com',
        hmt_url               => 'hmt.binary.com',
    );

    my $data;
    warnings_like {
        $data = Data::Validate::Sanctions::Fetcher::run(%test_args);
    }
    [
        qr/\bEU-Sanctions\b.*\bUser agent MockObject is hit by the url: eu.binary.com\b/,
        qr/\bHMT-Sanctions\b.*\bUser agent MockObject is hit by the url: hmt.binary.com\b/,
        qr/\bOFAC-Consolidated\b.*\bUser agent MockObject is hit by the url: ofac_con.binary.com\b/,
        qr/\bOFAC-SDN\b.*\bUser agent MockObject is hit by the url: ofac_snd.binary.com\b/,
    ],
        'Source urls are updated by params';

    is $calls, 3 * 4, 'the fetcher tried thrice per source and failed finally.';

    is_deeply $data, {}, 'There is no result with invalid urls';

};

subtest 'EU Sanctions' => sub {
    my $source_name = 'EU-Sanctions';
    my $data;

    warnings_like {
        $data = Data::Validate::Sanctions::Fetcher::run(%args, eu_url => undef);
    }
    [qr/EU Sanctions will fail whithout eu_token or eu_url/, qr/Url is empty for EU-Sanctions/],
        'Correct warning when the EU sanctions token is missing';

    is $data->{$source_name}, undef, 'Result is empty as expected';

    warning_like {
        $data = Data::Validate::Sanctions::Fetcher::run(
            %args,
            eu_url   => undef,
            eu_token => 'ASDF'
        );
    }
    qr(\bEU-Sanctions\b.*\bUser agent MockObject is hit by the url: https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content\?token=ASDF\b),
        'token is added to the default url';
    is $data->{$source_name}, undef, 'Result is empty';

    warning_like {
        $data = Data::Validate::Sanctions::Fetcher::run(
            %args,
            eu_url   => 'http://dummy.binary.com',
            eu_token => 'ASDF'
        );
    }
    qr(\bEU-Sanctions\b.*\bUser agent MockObject is hit by the url: http://dummy.binary.com at\b), 'token is not added to eu_url value';

    $data = Data::Validate::Sanctions::Fetcher::run(%args);
    ok $data->{$source_name}, 'EU Sanctions are loaded from the sample file';
    is $data->{$source_name}{updated}, 1586908800, "EU sanctions update date matches the sample file";

    is scalar $data->{$source_name}{content}->@*, 7, "Number of names matches the content of the sample EU sanction";

    is_deeply find_entry_by_name($data->{$source_name}, 'Salem ALI'),
        {
        'dob_epoch' => [-148867200, -184204800],
        'names'     => ['Fahd Bin Adballah BIN KHALID', 'Khalid Shaikh MOHAMMED', 'Salem ALI', 'Khalid Adbul WADOOD', 'Ashraf Refaat Nabith HENIN'],
        'passport_no'    => ['488555'],
        'place_of_birth' => ['pk'],
        },
        'multiple names and epochs extacted from a single entry';

    is_deeply find_entry_by_name($data->{$source_name}, 'Abid Hammadou'),
        {
        'citizen'        => ['dz'],
        'dob_epoch'      => [-127958400],
        'dob_year'       => ['1958'],
        'names'          => ['Abid Hammadou', 'Abdelhamid Abou Zeid', 'Youcef Adel', 'Amor Mohamed Ghedeir', 'Abou Abdellah'],
        'place_of_birth' => ['dz'],
        },
        'Cases with both epoch and year';

    is_deeply find_entry_by_name($data->{$source_name}, 'Yu-ro Han'), {'names' => ['Yu-ro Han']}, 'Cases with name only';

    is_deeply find_entry_by_name($data->{$source_name}, 'Leo Manzi'),
        {
        'citizen'        => ['rw'],
        'dob_year'       => ['1954', '1953'],
        'names'          => ['Leo Manzi'],
        'place_of_birth' => ['rw'],
        'residence'      => ['cd']
        },
        'Case with multiple years';

    is_deeply find_entry_by_name($data->{$source_name}, 'Mohamed Ben Belkacem Aouadi'),
        {
        'citizen'        => ['tn'],
        'dob_epoch'      => [155952000],
        'names'          => ['Mohamed Ben Belkacem Aouadi'],
        'national_id'    => ['04643632'],
        'nationality'    => ['tn'],
        'passport_no'    => ['L191609'],
        'place_of_birth' => ['tn'],
        'residence'      => ['tn']
        },
        'All fields are correctly extracted';
};

subtest 'HMT Sanctions' => sub {
    my $source_name = 'HMT-Sanctions';
    my $data;

    $data = Data::Validate::Sanctions::Fetcher::run(%args);
    ok $data->{$source_name}, 'HMT Sanctions are loaded from the sample file';
    is $data->{$source_name}{updated}, 1587945600, "Sanctions update date matches the sample file";
    is scalar $data->{$source_name}{content}->@*, 23, "Number of names matches the content of the sample file";

    is_deeply find_entry_by_name($data->{$source_name}, 'HOJATI Mohsen'),
        {
        'names'     => ['HOJATI Mohsen', 'محسن حجتی'],
        'dob_epoch' => [-450057600],
        },
        'Cases with a single epoch';

    is_deeply find_entry_by_name($data->{$source_name}, 'HUBARIEVA Kateryna Yuriyivna'),
        [{
            'dob_epoch'      => [426211200],
            'names'          => ['HUBARIEVA Kateryna Yuriyivna'],
            'place_of_birth' => ['ua']
        },
        {
            'dob_year'       => ['1983'],
            'names'          => ['HUBARIEVA Kateryna Yuriyivna'],
            'place_of_birth' => ['ua']
        },
        {
            'dob_year'       => ['1984'],
            'names'          => ['HUBARIEVA Kateryna Yuriyivna'],
            'place_of_birth' => ['ua']}
        ],
        'Multiple entries with the same name: one with dob epoch, others with dob years';

    is find_entry_by_name($data->{$source_name}, 'SO Sang Kuk')->@*, 7, 'Multiple entries with the same name  SO Sang Kuk';

    is find_entry_by_name($data->{$source_name}, 'PLOTNITSKII Igor Venediktovich')->@*, 3, 'Multiple entries with the same name PLOTNITSKII';

    is_deeply find_entry_by_name($data->{$source_name}, 'SAEED Hafez Mohammad'),
        {
        'names'          => ['SAEED Hafez Mohammad', 'سعید حافظ محمد'],
        'dob_epoch'      => [-617760000],
        'national_id'    => ['3520025509842-7'],
        'place_of_birth' => ['pk'],
        'residence'      => ['pk'],
        'postal_code'    => ['123321'],
        },
        'All fields extracted with (explanation) removed';
};

subtest 'OFAC Sanctions' => sub {
    my $data = Data::Validate::Sanctions::Fetcher::run(%args);

    for my $source_name ('OFAC-SDN', 'OFAC-Consolidated') {
        # OFAC sources have the same structure. We've created the samle sample file for both of them.

        ok $data->{$source_name}, 'Sanctions are loaded from the sample file';
        is $data->{$source_name}{updated}, 1587513600, "Sanctions update date matches the content of sample file";
        is scalar $data->{$source_name}{content}->@*, 6, "Number of names matches the content of the sample file";

        my $dataset = $data->{$source_name}->{names_list};

        is_deeply find_entry_by_name($data->{$source_name}, 'Hafiz Muhammad SAEED'),
            {
            'names' => [
                'Muhammad SAEED',
                'Hafiz Muhammad SAEED',
                'Hafiz SAEED',
                'Hafiz Mohammad SAEED',
                'Hafez Mohammad SAYEED',
                'Hafiz Mohammad SAYID',
                'Hafiz Mohammad SYEED',
                'Hafiz Mohammad SAYED',
                'Muhammad SAEED HAFIZ'
            ],
            'dob_epoch'      => [-617760000],
            'national_id'    => ['23250460642',      '3520025509842-7'],
            'passport_no'    => ['Booklet A5250088', 'BE5978421'],
            'place_of_birth' => ['pk'],
            'residence'      => ['pk']
            },
            "Alias names as saved in a single entry";

        is_deeply find_entry_by_name($data->{$source_name}, 'Mohammad Reza NAQDI'),
            {
            'names' => [
                'Mohammad Reza NAQDI',
                'Mohammad Reza NAGHDI',
                'Mohammad Reza SHAMS',
                'Muhammad NAQDI',
                'Mohammad-Reza NAQDI',
                'Mohammedreza NAGHDI',
                'Gholamreza NAQDI',
                'Gholam-reza NAQDI',
            ],
            'dob_year'       => [1951, 1952, 1953, 1960, 1961, 1962],
            'place_of_birth' => ['iq', 'ir'],
            'residence'      => ['ir']
            },
            "Range dob year + multiple places of birth";

        is_deeply find_entry_by_name($data->{$source_name}, 'Donald Trump'),
            {
            'names'     => ['Donald Trump'],
            'dob_text'  => ['circa-1951'],
            'residence' => ['us']
            },
            'dob_text is correctly extracted';
    }
};

sub find_entry_by_name {
    my ($data, $name) = @_;

    my @result;
    for my $entry ($data->{content}->@*) {
        push(@result, $entry) if any { $_ eq $name } $entry->{names}->@*;
    }

    return undef unless @result;

    return $result[0] if 1 == scalar @result;

    return \@result;
}

done_testing;
