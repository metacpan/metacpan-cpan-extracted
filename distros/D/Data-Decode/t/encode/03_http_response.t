use strict;
use File::Spec;
use Test::More (tests => 21);

BEGIN
{
    use_ok("Data::Decode");
    use_ok("Data::Decode::Encode::HTTP::Response");
}
use Encode;
use HTTP::Response;

my $decoder = Data::Decode->new(
    strategy => Data::Decode::Encode::HTTP::Response->new
);
ok($decoder);
isa_ok($decoder, "Data::Decode");
isa_ok($decoder->decoder, "Data::Decode::Encode::HTTP::Response");

# Make sure that we can decode everything that has charset specs in 
# the meta tags, and from content-type
my $response;
foreach my $encoding qw(euc-jp shiftjis 7bit-jis utf8) {
    my $file = File::Spec->catfile("t", "encode", "data", "$encoding.txt");
    open(DATAFILE, $file) or die "Could not open file $file: $!";
    my $string = do { local $/ = undef; <DATAFILE> };
    close(DATAFILE);

    $response = HTTP::Response->new(
        200,
        "OK", 
        undef,
        qq{<html><head><meta http-equiv="Content-Type" content="text/html; charset=$encoding"></head><body>$string</body></html>}
    );
    
    is($decoder->decode($string, { response => $response }), Encode::decode($encoding, $string), "META charset=$encoding");

    $response = HTTP::Response->new(
        200,
        "OK",
        HTTP::Headers->new( Content_Type => "text/html; charset=$encoding" ),
        qq{<html><head></head><body>$string</body></html>}
    );
        
    is($decoder->decode($string, { response => $response }), Encode::decode($encoding, $string), "Header charset=$encoding");

    # Now we attempt to fool our decoder by passing in a response object
    # that contains UTF-8 as its header, but the META tag says that the
    # content is $encoding (and $encoding is the correct one)

    $response = HTTP::Response->new(
        200,
        "OK",
        HTTP::Headers->new( Content_Type => "text/html; charset=UTF-8" ),
        qq{<html><head><meta http-equiv="Content-Type" content="text/html; charset=$encoding"></head><body>$string</body></html>}
    );

    SKIP: {
        skip("$encoding doesn't quite work when compared against utf-8, skipping", 1) if ($encoding eq '7bit-jis');
        is($decoder->decode($string, { response => $response }), Encode::decode($encoding, $string), "Header charset=UTF-8, META charset=$encoding");
    }

    $response = HTTP::Response->new(
        200,
        "OK",
        HTTP::Headers->new( Content_Type => "text/html; charset=$encoding" ),
        qq{<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></head><body>$string</body></html>}
    );

    is($decoder->decode($string, { response => $response }), Encode::decode($encoding, $string), "Header charset=$encoding, META charset=UTF-8");
}