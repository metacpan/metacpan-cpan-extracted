#!/usr/local/bin/perl

#
# Test that the primitive operators are working
#

use Convert::BER;

print "1..19\n";

$test = 1;
$tcount = 0;

#######################################################################
$tcount += 5;

$ber = Convert::BER->new->encode(
	SEQUENCE_OF => [ 4,
	    INTEGER => 1
	]);

while($ber) {
    print "ok ",$test++,"\n";

    $result = pack("C*", 0x30, 0x0C, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01,
			 0x02, 0x01, 0x01, 0x02, 0x01, 0x01);

    last
	unless $ber->buffer eq $result;
    print "ok ",$test++,"\n";

    my $i;
    my $count;

    $ber->decode(
	SEQUENCE_OF => [ \$count,
	    INTEGER => \$i
	]
    ) or last;
    print "ok ",$test++,"\n";

    last unless $i == 1;
    print "ok ",$test++,"\n";

    last unless $count == 4;
    print "ok ",$test++,"\n";

    last;
}

print "not ok ",$test++,"\n"
	while($test <= $tcount);

#######################################################################
$tcount += 7;

my %hash = ( Fred => "A string for fred", Joe => [qw(has a list of strings)]);

$ber = Convert::BER->new->encode(
	SEQUENCE_OF => [ \%hash,
	    STRING => sub { $_[0] },
	    SEQUENCE => [
		STRING => sub { $hash{ $_[0] } }
	    ]
	]);

while($ber) {
    print "ok ",$test++,"\n";

    $result = pack("C*", 0x30, 0x3D, 0x04, 0x04, 0x46, 0x72, 0x65, 0x64,
			 0x30, 0x13, 0x04, 0x11, 0x41, 0x20, 0x73, 0x74,
			 0x72, 0x69, 0x6E, 0x67, 0x20, 0x66, 0x6F, 0x72,
			 0x20, 0x66, 0x72, 0x65, 0x64, 0x04, 0x03, 0x4A,
			 0x6F, 0x65, 0x30, 0x1B, 0x04, 0x03, 0x68, 0x61,
			 0x73, 0x04, 0x01, 0x61, 0x04, 0x04, 0x6C, 0x69,
			 0x73, 0x74, 0x04, 0x02, 0x6F, 0x66, 0x04, 0x07,
			 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x73);

    unless ($ber->buffer eq $result) {
      # This test is a bit naughty as it depends on the hash order of
      # perl. Unfortunatley this changed in 5.7 so we have a different result
      $result = pack("C*", 0x30, 0x3D, 0x04, 0x03, 0x4A, 0x6F, 0x65, 0x30,
			   0x1B, 0x04, 0x03, 0x68, 0x61, 0x73, 0x04, 0x01,
			   0x61, 0x04, 0x04, 0x6C, 0x69, 0x73, 0x74, 0x04,
			   0x02, 0x6F, 0x66, 0x04, 0x07, 0x73, 0x74, 0x72,
			   0x69, 0x6E, 0x67, 0x73, 0x04, 0x04, 0x46, 0x72,
			   0x65, 0x64, 0x30, 0x13, 0x04, 0x11, 0x41, 0x20,
			   0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x20, 0x66,
			   0x6F, 0x72, 0x20, 0x66, 0x72, 0x65, 0x64);

    }

    unless ($ber->buffer eq $result) {
      print "# Expecting\n";
      Convert::BER->new($result)->hexdump(*STDOUT);
      print "# Got\n";
      $ber->hexdump(*STDOUT);
      last;
    }

    print "ok ",$test++,"\n";

    my @arr = ();
    my %h;

    $ber->decode(
	SEQUENCE_OF => [ \$count,
	    STRING => sub { \$arr[$_[0]] } ,
	    SEQUENCE => [
		STRING => sub { $h{$arr[$_[0]]} ||= [] }
	    ]
	]
    ) or last;

    print "ok ",$test++,"\n";

    last
	unless @arr == 2;

    print "ok ",$test++,"\n";

    last
	unless $count == 2;

    print "ok ",$test++,"\n";

    last
	unless ref($h{Fred}) eq 'ARRAY' && @{$h{Fred}} == 1 &&
		$h{Fred}->[0] eq "A string for fred";

    print "ok ",$test++,"\n";

    last
	unless ref($h{Joe}) eq 'ARRAY' && @{$h{Joe}} == 5 &&
		join("~",@{$h{Joe}}) eq "has~a~list~of~strings";

    print "ok ",$test++,"\n";

    last;
}

print "not ok ",$test++,"\n"
	while($test <= $tcount);

#######################################################################
$tcount += 7;

my @array = ( [qw(A list)],[qw(of lists)]);

$ber = Convert::BER->new->encode(
	SEQUENCE_OF => [ \@array,
	    SEQUENCE => [
		STRING => sub { $_[0] },
	    ]
	]);

while($ber) {
    print "ok ",$test++,"\n";

    $result = pack("C*", 0x30, 0x18, 0x30, 0x09, 0x04, 0x01, 0x41, 0x04,
			 0x04, 0x6C, 0x69, 0x73, 0x74, 0x30, 0x0B, 0x04,
			 0x02, 0x6F, 0x66, 0x04, 0x05, 0x6C, 0x69, 0x73,
			 0x74, 0x73);

    last
	unless $ber->buffer eq $result;

    print "ok ",$test++,"\n";

    my @arr = ();
    my %h;

    $ber->decode(
	SEQUENCE_OF => [ \$count,
	    SEQUENCE => [
		STRING => sub { $arr[$_[0]] ||= [] }
	    ]
	]
    ) or last;

    print "ok ",$test++,"\n";

    last
	unless @arr == 2;

    print "ok ",$test++,"\n";

    last
	unless $count == 2;

    print "ok ",$test++,"\n";

    last
	unless ref($arr[0]) eq 'ARRAY' && @{$arr[0]} == 2 &&
		join("~",@{$arr[0]}) eq "A~list";

    print "ok ",$test++,"\n";

    last
	unless ref($arr[1]) eq 'ARRAY' && @{$arr[1]} == 2 &&
		join("~",@{$arr[1]}) eq "of~lists";
    print "ok ",$test++,"\n";

    last;
}

print "not ok ",$test++,"\n"
	while($test <= $tcount);
