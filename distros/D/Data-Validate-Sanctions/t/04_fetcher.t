use strict;
use warnings;
use utf8;

use Class::Unload;
use Data::Validate::Sanctions;
use Data::Validate::Sanctions::Fetcher;
use YAML::XS   qw(Dump);
use Path::Tiny qw(tempfile);
use List::Util qw(first);
use Test::More;
use Test::Deep;
use Test::Warnings;
use Test::MockModule;
use Test::Warn;
use Test::MockObject;
use List::Util;
use Digest::SHA qw(sha256_hex);

use JSON;

my %args = (
    eu_url                => "file://t/data/sample_eu.xml",
    ofac_sdn_url          => "file://t/data/sample_ofac_sdn.zip",
    ofac_consolidated_url => "file://t/data/sample_ofac_consolidated.xml",
    hmt_url               => "file://t/data/sample_hmt.csv",
    unsc_url              => "file://t/data/sample_unsc.xml",
    handler               => sub { },
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
        handler               => sub { },
    );

    my $data = Data::Validate::Sanctions::Fetcher::run(%test_args);
    cmp_deeply $data,
        {
        'HMT-Sanctions' => {
            error => ignore(),
        },
        'OFAC-Consolidated' => {
            error => ignore(),
        },
        'EU-Sanctions' => {
            error => ignore(),
        },
        'OFAC-SDN' => {
            error => ignore(),
        },
        'UNSC-Sanctions' => {
            error => ignore(),
        },
        },
        'All sources return errors - no content';

    is $calls, 3 * 5, 'the fetcher tried thrice per source and failed finally.';

};

subtest 'EU Sanctions' => sub {
    my $source_name = 'EU-Sanctions';
    my $data;

    warnings_like {
        $data = Data::Validate::Sanctions::Fetcher::run(%args, eu_url => undef);
    }
    [qr/EU Sanctions will fail whithout eu_token or eu_url/], 'Correct warning when the EU sanctions token is missing';

    cmp_deeply $data->{$source_name}, {error => ignore()}, 'There is an error in the result';
    like $data->{$source_name}->{error}, qr/Url is empty for EU-Sanctions/, 'Correct error for missing EU url';

    $data = Data::Validate::Sanctions::Fetcher::run(
        %args,
        eu_url   => undef,
        eu_token => 'ASDF'
    );
    like $data->{$source_name}->{error},
        qr(\bUser agent MockObject is hit by the url: https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content\?token=ASDF\b),
        'Token is added to the URL in error message';

    $data = Data::Validate::Sanctions::Fetcher::run(
        %args,
        eu_url   => 'http://dummy.binary.com',
        eu_token => 'ASDF'
    );
    like $data->{$source_name}->{error}, qr(\bUser agent MockObject is hit by the url: http://dummy.binary.com\b),
        'eu_url argument is directly used, without eu_token modification';

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
    is $data->{$source_name}{updated},            1587945600, "Sanctions update date matches the sample file";
    is scalar $data->{$source_name}{content}->@*, 23,         "Number of names matches the content of the sample file";

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
        is $data->{$source_name}{updated},            1587513600, "Sanctions update date matches the content of sample file";
        is scalar $data->{$source_name}{content}->@*, 6,          "Number of names matches the content of the sample file";

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

# Test _epoch_to_date
subtest '_epoch_to_date' => sub {
    # Test valid epoch
    is Data::Validate::Sanctions::Fetcher::_epoch_to_date(1672444800), '2022-12-31', 'Valid epoch timestamp';

    # Test another valid epoch
    is Data::Validate::Sanctions::Fetcher::_epoch_to_date(1609459200), '2021-01-01', 'Another valid epoch timestamp';

    # Test invalid epoch (undefined)
    {
        my $error;
        eval { Data::Validate::Sanctions::Fetcher::_epoch_to_date(undef) };
        $error = $@;
        like($error, qr/Epoch timestamp must be defined/, 'Undefined epoch timestamp');
    }

    # Test invalid epoch (non-numeric)
    {
        my $error;
        eval { Data::Validate::Sanctions::Fetcher::_epoch_to_date('invalid') };
        $error = $@;
        like($error, qr/Validation failed for type named Num/, 'Non-numeric epoch timestamp');
    }

    # Test epoch for a date in the past
    is Data::Validate::Sanctions::Fetcher::_epoch_to_date(-315619200), '1960-01-01', 'Epoch timestamp for a date in the past';
};

# Test _clean_url
subtest '_clean_url' => sub {
    # Test URL with token parameter
    is Data::Validate::Sanctions::Fetcher::_clean_url('http://example.com?token=abc123'), 'http://example.com', 'URL with token parameter';

    # Test URL with multiple parameters including token
    is Data::Validate::Sanctions::Fetcher::_clean_url('http://example.com?param1=value1&token=abc123&param2=value2'),
        'http://example.com?param1=value1&param2=value2', 'URL with multiple parameters including token';

    # Test URL without token parameter
    is Data::Validate::Sanctions::Fetcher::_clean_url('http://example.com?param1=value1&param2=value2'),
        'http://example.com?param1=value1&param2=value2', 'URL without token parameter';

    # Test URL with token parameter at the end
    is Data::Validate::Sanctions::Fetcher::_clean_url('http://example.com?param1=value1&param2=value2&token=abc123'),
        'http://example.com?param1=value1&param2=value2', 'URL with token parameter at the end';

    # Test URL with token parameter in the middle
    is Data::Validate::Sanctions::Fetcher::_clean_url('http://example.com?param1=value1&token=abc123&param2=value2'),
        'http://example.com?param1=value1&param2=value2', 'URL with token parameter in the middle';

    # Test URL with only token parameter
    is Data::Validate::Sanctions::Fetcher::_clean_url('http://example.com?token=abc123'), 'http://example.com', 'URL with only token parameter';
};

# Test _create_hash
subtest '_create_hash' => sub {
    # Test hash creation for simple data
    is Data::Validate::Sanctions::Fetcher::_create_hash({key => 'value'}), sha256_hex(to_json({key => 'value'}, {canonical => 1, utf8 => 1})),
        'Hash creation for simple data';

    # Test hash creation for complex data
    my $complex_data = {
        key1 => 'value1',
        key2 => [1, 2, 3],
        key3 => {subkey => 'subvalue'}};
    is Data::Validate::Sanctions::Fetcher::_create_hash($complex_data), sha256_hex(to_json($complex_data, {canonical => 1, utf8 => 1})),
        'Hash creation for complex data';

    # Test hash creation for empty data
    is Data::Validate::Sanctions::Fetcher::_create_hash({}), sha256_hex(to_json({}, {canonical => 1, utf8 => 1})), 'Hash creation for empty data';

    # Test hash creation for nested data
    my $nested_data = {
        key1 => 'value1',
        key2 => {
            subkey1 => 'subvalue1',
            subkey2 => [4, 5, 6]}};
    is Data::Validate::Sanctions::Fetcher::_create_hash($nested_data), sha256_hex(to_json($nested_data, {canonical => 1, utf8 => 1})),
        'Hash creation for nested data';

    # Test hash creation for data with special characters
    my $special_data = {
        key1 => 'value1',
        key2 => 'value with special characters: !@#$%^&*()'
    };
    is Data::Validate::Sanctions::Fetcher::_create_hash($special_data), sha256_hex(to_json($special_data, {canonical => 1, utf8 => 1})),
        'Hash creation for data with special characters';
};

subtest 'UNSC Sanctions' => sub {
    my $data = Data::Validate::Sanctions::Fetcher::run(%args);

    my $source_name = 'UNSC-Sanctions';
    ok $data->{$source_name}, 'Sanctions are loaded from the sample file';
    is $data->{$source_name}{updated},           1729123202, "Sanctions update date matches the content of sample file";
    is scalar @{$data->{$source_name}{content}}, 7,          "Number of names matches the content of the sample file";

    is_deeply find_entry_by_name($data->{$source_name}, 'MOHAMMAD NAIM'),
        {
        'national_id'    => [[]],
        'place_of_birth' => ['af'],
        'citizen'        => ['af'],
        'nationality'    => ['af'],
        'postal_code'    => ['63000'],
        'passport_no'    => [[]],
        'dob_year'       => ['1975'],
        'names'          => [
            'MOHAMMAD NAIM',
            'BARICH',
            'KHUDAIDAD',
            "\x{645}\x{62d}\x{645}\x{62f} \x{646}\x{639}\x{64a}\x{645} \x{628}\x{631}\x{64a}\x{62e} \x{62e}\x{62f}\x{627}\x{64a}\x{62f}\x{627}\x{62f}",
            'Mullah Naeem Barech',
            'Mullah Naeem Baraich',
            'Mullah Naimullah',
            'Mullah Naim Bareh',
            'Mohammad Naim',
            'Mullah Naim Barich',
            'Mullah Naim Barech',
            'Mullah Naim Barech Akhund',
            'Mullah Naeem Baric',
            'Naim Berich',
            'Haji Gul Mohammed Naim Barich',
            'Gul Mohammad',
            'Haji Ghul Mohammad',
            'Spen Zrae',
            'Gul Mohammad Kamran',
            'Mawlawi Gul Mohammad'
        ]
        },
        'Alias names as saved in a single entry';
};

sub find_entry_by_name {
    my ($data, $name) = @_;

    my @result;

    for my $entry ($data->{content}->@*) {
        push(@result, $entry) if List::Util::any { $_ eq $name } $entry->{names}->@*;
    }

    return undef unless @result;

    return $result[0] if 1 == scalar @result;

    return \@result;
}

done_testing();
