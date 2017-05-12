use strict;
use warnings;
use Test;
use Data::Sync;

BEGIN {
    plan tests => 3;
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

$synchandle->validation(	address=>"/St\./",
				name=>"/user/i"	);



my $result = $synchandle->runtransform( \@AoH );

# make sure the transform actually happened
ok($result);


# check for correct validation
my $validation = $synchandle->validate(\@AoH);

ok($validation);

# check for validation failure
push @AoH,{	name=>"testfail",
		address=>"no address"	};

$validation = $synchandle->validate(\@AoH);

ok(!$validation);

