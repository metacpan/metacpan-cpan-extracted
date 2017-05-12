use strict;
use warnings;
use Archive::Zip;
use Archive::Zip::Crypt;
use Test::More tests => 3;

my %results;

my $zip = Archive::Zip->new('t/archive.zip');
isnt($zip, undef, "new() succeeded");
foreach my $member_name ($zip->memberNames) {
    my $member = $zip->memberNamed($member_name);
    next if $member->isDirectory;
    $member->password($member_name);    # password is member name in test archive
    my $contents = $zip->contents($member) or die "error accessing $member_name";
    $results{$member_name} = $contents;
}
is($results{test1}, "foo\n", "First member unzipped");
is($results{test2}, "bar\n", "Second member unzipped");
