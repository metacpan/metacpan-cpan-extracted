use strict;
use warnings;
use Test;
use Data::Sync;

BEGIN {
    plan tests => 9;
}

my $synchandle = Data::Sync->new();

# test internal transformation methods of Data::Sync

my @AoH = (
    {
        "name"        => "Test User",
        "address"     => "1 Test Street",
        "phone"       => "01234 567890",
        "description" => "Test string"
    },
    {
        "name"    => "Test user 2",
        "address" => [ "1 Office Street", "2 Office Street" ],
        "phone"   => [ "01234 567891", "01234 567892" ]
    },
    {
        "name"    => "Test user 3",
        "address" => [ [ "1 Home Street", "2 Home Street" ], "3 Office Street" ]
    },
    {
        "name"        => "Test user 4",
        "longaddress" => "123 Test Street\nTest Town\nUK"
    },
    {
	"lowerattrib" => "Some Chars In Lower Case",
	"upperattrib" => "Some Chars In Upper Case"
    },
    {
	"multivaluedattrib" => [
				"one",
				"two",
				"three"
				]
    }
);

$synchandle->transforms(
    name    => "stripspaces",
    address => sub {
        my $var = shift;
        $var =~ s/Street/St./g;
        return $var;
    },
    phone         => 's/^0(\d{4})/\+44 $1/',
    longaddress   => "stripnewlines",
    "description" => "",
    lowerattrib	  => "uppercase",
    upperattrib   => "lowercase",
    multivaluedattrib => "concatenate",
    
);

my $result = $synchandle->runtransform( \@AoH );

# check names
my $namesok = 1;
if ( $result->[0]->{'name'} ne "TestUser" )  { $namesok-- }
if ( $result->[1]->{'name'} ne "TestUser2" ) { $namesok-- }
if ( $result->[2]->{'name'} ne "TestUser3" ) { $namesok-- }
ok($namesok);

# check addresses
my $addressesok = 1;
if ( $result->[0]->{'address'}           ne "1 Test St." )   { $addressesok-- }
if ( $result->[1]->{'address'}->[0]      ne "1 Office St." ) { $namesok-- }
if ( $result->[1]->{'address'}->[1]      ne "2 Office St." ) { $namesok-- }
if ( $result->[2]->{'address'}->[1]      ne "3 Office St." ) { $namesok-- }
if ( $result->[2]->{'address'}->[0]->[0] ne "1 Home St." )   { $namesok-- }
if ( $result->[2]->{'address'}->[0]->[1] ne "2 Home St." )   { $namesok-- }
ok($namesok);

# check phone numbers
my $phoneok = 1;
if ( $result->[0]->{'phone'}      ne "+44 1234 567890" ) { $phoneok-- }
if ( $result->[1]->{'phone'}->[0] ne "+44 1234 567891" ) { $phoneok-- }
if ( $result->[1]->{'phone'}->[1] ne "+44 1234 567892" ) { $phoneok-- }
if ( $result->[2]->{'phone'} ) { $phoneok-- }
ok($phoneok);

# check for newline removal
my $nlok = 1;
if ( $result->[3]->{'longaddress'} ne "123 Test Street Test Town UK" ) {
    $nlok--;
}
ok($nlok);

#check for null transform
my $nullok = 1;
if ( $result->[0]->{'description'} ne "Test string" ) { $nullok-- }
ok($nullok);

# check upper and lower casing functions
my $casecheck1 = 1;
my $casecheck2 = 1;
if ($result->[4]->{'lowerattrib'} ne "SOME CHARS IN LOWER CASE"){$casecheck1--}
if ($result->[4]->{'upperattrib'} ne "some chars in upper case"){$casecheck2--}
ok($casecheck1);
ok($casecheck2);

# check concatenation function
my $mvcheck=1;
if ($result->[5]->{'multivaluedattrib'} ne "one|two|three"){$mvcheck--}
ok($mvcheck);

# check mvseparator returns the separator value
my $sepcheck=1;
$synchandle->mvseparator('$');
if ($synchandle->mvseparator ne '$'){$sepcheck--}
ok($sepcheck);
