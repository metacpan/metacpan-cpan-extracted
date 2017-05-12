######################################################################
# Test suite for Bot::WootOff
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;
plan tests => 8;

my $canned_dir = "t/canned";
$canned_dir = "../$canned_dir" unless -d $canned_dir;

use Bot::WootOff;

my $bot = Bot::WootOff->new(spawn => 0);

for my $file (qw(woot-20121022.html woot-20090903.html woot-legacy.html)) {
    my($item, $price) = $bot->html_scrape( slurp("$canned_dir/$file") );

    is $item, "Some product with some description", "item parsed";
    is $price, "19.99", "price parsed";

}

my($item, $price) = 
    $bot->html_scrape( slurp("$canned_dir/woot-20121108.html") );
is $item, "TDK Boombox", "item";
is $price, "139.99 - 219.99", "price";

sub slurp {
    my($file) = @_;
    open FILE, "<$file" or die $!;
    local($/) = undef;
    my $data = <FILE>;
    close FILE;
    return $data;
}
