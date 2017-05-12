#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
use Data::ParseBinary;
use Test::More tests => 27;
#use Test::More qw(no_plan);
$| = 1;

my ($data1, $data2);
my $string;
my $inner;
my $s;
my $stream1;
my $stream2;

$s = Struct("foo",
    UBInt8("a"),
    SLInt16("b")
);
$string = "\x07\x00\x01";
$data1 = {a => 7, b => 256};
$stream1 = CreateStreamReader($string);
is_deeply( $s->parse($stream1), $data1, "String Stream: Parse: Simple");
$stream1 = CreateStreamWriter("");
$s->build($data1, $stream1);
ok( $stream1->Flush() eq $string, "String Stream: Build: Simple");
$s->build($data1, $stream1);
ok( $stream1->Flush() eq $string.$string, "String Stream: Build: Twice");
$string = "\x07\x00\x01\x08\x00\x01";
$data1 = {a => 7, b => 256};
$data2 = {a => 8, b => 256};
$stream1 = CreateStreamReader($string);
is_deeply( $s->parse($stream1), $data1, "String Stream: Parse: First of two");
is_deeply( $s->parse($stream1), $data2, "String Stream: Parse: Second of two");

$stream1 = CreateStreamWriter("\x07\x00\x01");
$data1 = {a => 8, b => 256};
$string = "\x07\x00\x01\x08\x00\x01";
$s->build($data1, $stream1);
ok( $stream1->Flush() eq $string, "String Stream: Build: Continues");

$inner = "\x07\x00\x01";
$stream1 = CreateStreamWriter(StringRef=>\$inner);
$data1 = {a => 8, b => 256};
$string = "\x07\x00\x01\x08\x00\x01";
$s->build($data1, $stream1);
ok( $inner eq $string, "StringRef Stream: Build: Continues1");
ok( ${ $stream1->Flush() } eq $string, "StringRef Stream: Build: Continues2");

$inner = "\x07\x00\x01\x08\x00\x01";
$data1 = {a => 7, b => 256};
$data2 = {a => 8, b => 256};
$stream1 = CreateStreamReader(StringRef=>\$inner);
is_deeply( $s->parse($stream1), $data1, "StringRef Stream: Parse: First of two");
is_deeply( $s->parse($stream1), $data2, "StringRef Stream: Parse: Second of two");

$stream2 = CreateStreamReader(StringRef=>\$inner);
$stream1 = CreateStreamReader(StringBuffer => $stream2);
is_deeply( $s->parse($stream1), $data1, "StringBuffer Stream: Parse: Start");
ok( $stream2->tell() == 3, "StringBuffer Stream: Parse: Step1");
is_deeply( $s->parse($stream1), $data2, "StringBuffer Stream: Parse: Step2");
ok( $stream2->tell() == 6, "StringBuffer Stream: Parse: End");
eval { $s->parse($stream1) };
ok( $@, "StringBuffer Stream: Parse: Dies");

$s = BitStruct("foo",
    Padding(1),
    Flag("myflag"),
    Padding(3),
);
$inner = "\x40\0";
$stream1 = CreateStreamReader(StringRef => \$inner);
$data1 = {myflag => 1};
$data2 = {myflag => 0};
is_deeply( $s->parse($stream1), $data1, "BitStruct over StringRef: Parse: First of two");
is_deeply( $s->parse($stream1), $data2, "BitStruct over StringRef: Parse: Second of two");

$inner = "\x42\0";
$stream1 = CreateStreamReader(Bit => StringRef => \$inner);
$data1 = {myflag => 1};
$data2 = {myflag => 0};
is_deeply( $s->parse($stream1), $data1, "Continues BitStream: Parse: First of three");
is_deeply( $s->parse($stream1), $data1, "Continues BitStream: Parse: Second of three");
is_deeply( $s->parse($stream1), $data2, "Continues BitStream: Parse: Third of three");

$inner = "\x40\x40\0";
$stream1 = CreateStreamWriter(Bit => String => undef);
$s->build($data1, $stream1);
$s->build($data1, $stream1);
$s->build($data2, $stream1);
ok( $stream1->Flush() eq $inner, "Continues BitStream: Build: OK");

$inner = "\x42\0";
$stream1 = CreateStreamWriter(Wrap => Bit => String => undef);
$s->build($data1, $stream1);
$s->build($data1, $stream1);
$s->build($data2, $stream1);
ok( $stream1->Flush()->Flush() eq $inner, "Continues BitStream: Build: OK");

$s = Struct("foo",
    Pointer(sub { 4 }, Byte("data1")),   # <-- data1 is at (absolute) position 4
    Pointer(sub { 7 }, Byte("data2")),   # <-- data2 is at (absolute) position 7
);
$data1 = {data1 => 1, data2=> 2};
$inner = "\x00\x00\x00\x00\x01\x00\x00\x02\0x01\0x01";
$stream2 = UnseekableReader->new($inner);
$stream1 = CreateStreamReader(StringBuffer => $stream2);
is_deeply( $s->parse($stream1), $data1, "StringBuffer: Parse: Pointer passed");
ok( $stream2->tell() == 8, "StringBuffer: Parse: Read the right amount");
$stream2 = UnseekableWriter->new();
$stream1 = CreateStreamWriter(StringBuffer => $stream2);
$inner = "\x00\x00\x00\x00\x01\x00\x00\x02";
ok( $s->build($data1, $stream1) eq $inner, "StringBuffer: Build: passed");

open my $fh, ">", "t_file_stream.bin" or die "Can not open temp file to write";
binmode $fh;
$stream1 = CreateStreamWriter(File => $fh);
$s->build($data1, $stream1);
close $fh;
open $fh, "<", "t_file_stream.bin" or die "Can not open temp file to read";
binmode $fh;
{
    local $/ = undef;
    my $content = <$fh>;
    ok($content eq $inner, "File: written OK");
}
seek($fh, 0, 0);
$stream1 = CreateStreamReader(File => $fh);
is_deeply( $s->parse($stream1), $data1, "File: read OK");
close $fh;
unlink "t_file_stream.bin";


#print Dumper($data1);

package UnseekableReader;
our @ISA;
BEGIN { @ISA = qw{Data::ParseBinary::Stream::StringReader} }

sub seek { die "UnseekableReader: seek should not be called" }

package UnseekableWriter;
our @ISA;
BEGIN { @ISA = qw{Data::ParseBinary::Stream::StringWriter} }

sub seek { die "UnseekableWriter: seek should not be called" }
