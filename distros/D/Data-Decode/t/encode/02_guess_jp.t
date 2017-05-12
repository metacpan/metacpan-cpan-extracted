use strict;
use File::Spec;
use Test::More (tests => 9);

BEGIN
{
    use_ok("Data::Decode");
    use_ok("Data::Decode::Encode::Guess::JP");
}
use Encode;

my $decoder = Data::Decode->new(
    strategy => Data::Decode::Encode::Guess::JP->new
);
ok($decoder);
isa_ok($decoder, "Data::Decode");
isa_ok($decoder->decoder, "Data::Decode::Encode::Guess::JP");

foreach my $encoding (@{ $decoder->decoder->encodings }) {
    my $file = File::Spec->catfile("t", "encode", "data", "$encoding.txt");
    open(DATAFILE, $file) or die "Could not open file $file: $!";

    my $string = do { local $/ = undef; <DATAFILE> };
    
    is($decoder->decode($string), Encode::decode($encoding, $string));
}
