use strict;
use warnings;
use BankDetails::India;
use Test::More;
use Test::Exception;
use Cwd;

# Get the current working directory
my $cwd = getcwd();

my $api = BankDetails::India->new(
    'cache_data' => CHI->new(
                        driver => 'File', 
                        namespace => 'bankdetails',
                        root_dir => $cwd . '/t/cache/'
                    )
);

# Call the get_contact_by_ifsc method
my $contact = $api->get_contact_by_ifsc('UTIB0000037');
ok(defined $contact, "get_contact_by_ifsc returns defined contact");

done_testing;