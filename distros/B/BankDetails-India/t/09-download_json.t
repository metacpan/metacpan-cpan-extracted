use strict;
use warnings;
use Test::More;
use Test::MockObject;
use BankDetails::India;

# Create a mock object for LWP::UserAgent
my $user_agent_mock = Test::MockObject->new();
$user_agent_mock->mock(
    get => sub {
        my ($self, $url) = @_;
        if ($url eq 'https://ifsc.razorpay.com/KKBK0005652') {
            return HTTP::Response->new( 200, 'OK', 
                                        ['Content-Type' => 'application/json'], 
                                        '{"BANK":"Kotak Mahindra Bank","BANKCODE":"KKBK","IFSC":"KKBK0005652"}'
                                    );
        }
    }
);

# Create an instance of BankDetails::India with mocked LWP::UserAgent
my $bank_api = BankDetails::India->new(user_agent => $user_agent_mock);

# Test download_json method
subtest "Test download_json method" => sub {
    # Mock ping_api method to always return 1 (API is online)
    $bank_api->meta->add_method(ping_api => sub { 1 });

    # Call the download_json method
    my $file_name = 'test_json_file.json';
    $bank_api->download_json('KKBK0005652', $file_name);

    # Read the content of the downloaded file
    open(my $fh, '<', $file_name) or die "Failed to open $file_name: $!";
    my $content = do { local $/; <$fh> };
    close($fh);

    # Check if the content matches the expected JSON
    is($content, '{"BANK":"Kotak Mahindra Bank","BANKCODE":"KKBK","IFSC":"KKBK0005652"}', "JSON content downloaded correctly");

    # Remove the file after the test is done
    unlink $file_name;
};

# Test download_json method when API is offline
subtest "Test download_json method with API offline" => sub {
    # Mock ping_api method to always return 0 (API is offline)
    $bank_api->meta->add_method(ping_api => sub { 0 });

    # Call the download_json method
    my $file_name = 'test_json_file.json';
    $bank_api->download_json('KKBK0005652', $file_name);

    # Check if the file is not created when API is offline
    ok(!-e $file_name, "JSON file not created when API is offline");
};

done_testing();
