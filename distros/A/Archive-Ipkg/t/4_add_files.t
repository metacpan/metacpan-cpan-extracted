# Test 3: Strict properties

use Test::More tests => 5;

use Archive::Ipkg;

# test strictness of properties
my $ipkg = Archive::Ipkg->new();

# return undef if file doesn't exist
my $a = $ipkg->add_files("weird_filename");
ok(!defined $a || $a == 0);
ok($ipkg->add_files("Makefile"));

ok($ipkg->add_file_by_data("filename", "some file contents"));

ok(!defined $ipkg->data(""), "data fails without required properties");

$ipkg->name("weird");
$ipkg->version("0.0");
$ipkg->maintainer("foo foo\@foobar.org");
$ipkg->description("A weird package!");

ok($ipkg->data(""), "data succeeds with required properties");

