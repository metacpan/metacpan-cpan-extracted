use strict;
use File::Spec;
use Test::More (tests => 12);

BEGIN
{
    use_ok("Data::Decode");
    use_ok("Data::Decode::Chain");
    use_ok("Data::Decode::Encode::Guess");
    use_ok("Data::Decode::Encode::Guess::JP");
}
use Encode;

my $decoder = Data::Decode->new(
    strategy => Data::Decode::Chain->new(
        decoders => [
            Data::Decode::Encode::Guess->new( encodings => [ 'hebrew' ] ),
            Data::Decode::Encode::Guess::JP->new
        ]
    )
);
ok($decoder);
isa_ok($decoder, "Data::Decode");
isa_ok($decoder->decoder, "Data::Decode::Chain");

my @encodings = qw(shiftjis 7bit-jis hebrew utf8 euc-jp);
foreach my $encoding (@encodings) {
    my $file = File::Spec->catfile("t", "encode", "data", "$encoding.txt");
    open(DATAFILE, $file) or die "Could not open file $file: $!";

    my $string = do { local $/ = undef; <DATAFILE> };
    
    is($decoder->decode($string), Encode::decode($encoding, $string), "$encoding recognized and decoded properly");
}