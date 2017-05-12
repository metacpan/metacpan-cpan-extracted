use strict;
use Test::More (tests => 6);
use File::Spec;

BEGIN
{
    use_ok("Data::Decode");
    use_ok("Data::Decode::Encode::Guess");
}
use Encode;

my $decoder = Data::Decode->new(
    strategy => Data::Decode::Encode::Guess->new(encodings => [ 'hebrew', 'shiftjis', 'utf8' ])
);
ok($decoder);
isa_ok($decoder, "Data::Decode");
isa_ok($decoder->decoder, "Data::Decode::Encode::Guess");


my $file = File::Spec->catfile("t", "encode", "data", "hebrew.txt");
open(DATAFILE, $file) or die "Could not open $file: $!";

my $string = do { local $/ = undef; <DATAFILE> };

is($decoder->decode($string), Encode::decode('hebrew', $string) );