use strict;
use warnings;
use Test;
use Data::Sync;

BEGIN
{
	plan tests=>1
}

my $fh;
open ($fh,">","logfile.txt");
my $synchandle = Data::Sync->new(log=>$fh);

# test internal transformation methods of Data::Sync

my @AoH = (	{"name"=>"Test User",
		"address"=>"1 Test Street",
		"phone"=>"01234 567890"},
		{"name"=>"Test user 2",
		"address"=>["1 Office Street","2 Office Street"],
		"phone"=>["01234 567891","01234 567892"]},
		{"name"=>"Test user 3",
		"address"=>[["1 Home Street","2 Home Street"],"3 Office Street"]});


$synchandle->transforms(name=>"stripspaces",
			address=>sub{
					my $var=shift;
					$var=~s/Street/St./g;
					return $var},
			phone=>'s/^0(\d{4})/\+44 $1/');

my $result = $synchandle->runtransform(\@AoH);

close $fh;

open ($fh,"<","logfile.txt") or die;
# Turn into a hash - all lines must be *present* but order may vary
my %logline;
my %comparisonline;
my $loggingok=1;

while (<$fh>)
{
	if ($_ ne "\n")
	{
		$logline{$_}++;
	}
}

# get the comparison lines from <DATA>
while (<DATA>)
{
	$comparisonline{$_}++;
}

for my $line (keys %logline)
{
	if ($comparisonline{$line} != 1)
	{
		$loggingok--;
	}
}
ok($loggingok);	
__DATA__
Transformed Test User to TestUser
Transformed 1 Test Street to 1 Test St.
Transformed 01234 567890 to +44 1234 567890
Transformed Test user 2 to Testuser2
Transformed 1 Office Street to 1 Office St.
Transformed 2 Office Street to 2 Office St.
Transformed 01234 567891 to +44 1234 567891
Transformed 01234 567892 to +44 1234 567892
Transformed Test user 3 to Testuser3
Transformed 1 Home Street to 1 Home St.
Transformed 2 Home Street to 2 Home St.
Transformed 3 Office Street to 3 Office St.
