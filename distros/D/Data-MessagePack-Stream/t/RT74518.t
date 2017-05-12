use strict;
use warnings;
use Test::More;
use Data::MessagePack;
use Data::MessagePack::Stream;

my @input = ([1, 0, undef, "0"], [1, 1, undef, "1"]);

my $input_bytes;
my @input_boundaries;
for(my $i=0; $i<@input; $i++) {
    $input_bytes .= Data::MessagePack->pack($input[$i]);
    push @input_boundaries, length $input_bytes;
}

my $packet_size = 4;
for my $packet_size (1..1+length $input_bytes) {
    note "Packet size: $packet_size";
    my @input_packets = unpack("(a$packet_size)*", $input_bytes);
    # note scalar @input_packets;

    my $mps = Data::MessagePack::Stream->new;

    my $pos = 0;
    my $m = 0;

    while (@input_packets) {
	my $packet = shift @input_packets;
	$pos += length $packet;
	$mps->feed($packet);
	while ($pos >= $input_boundaries[$m]) {
	    ok($mps->next, "$pos: complete message");
	    is_deeply($mps->data, $input[$m], "same message");
	    $m++;
	    last if $m >= @input_boundaries;
	}
	if (@input_packets && $pos < $input_boundaries[$m]) {
	    ok(! $mps->next, "$pos: incomplete message");
	}
    }
}

done_testing;
