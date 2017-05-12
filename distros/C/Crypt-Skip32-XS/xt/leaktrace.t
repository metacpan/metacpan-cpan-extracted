use strict;
use warnings;
use Crypt::Skip32::XS;
use Test::More;

eval "use Test::LeakTrace";
if ($@) {
    plan skip_all => 'Test::LeakTrace is not installed.';
}
plan tests => 1;

my $try = sub {
    my $key    = pack("H20", "112233445566778899AA");
    my $text   = pack("N", 3493209676);
    my $cipher = Crypt::Skip32::XS->new($key);

    $cipher->decrypt($cipher->encrypt($text));
};

$try->();

is( leaked_count($try), 0, 'leaks' );
