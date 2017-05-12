#!/usr/local/bin/perl

#
# Test the use of sequences
#

use Convert::BER;

print "1..5\n";

$test = 1;

$ber = Convert::BER->new->encode(
    SEQUENCE => [
	INTEGER => 1,
	BOOLEAN => 0,
	STRING => "A string"
    ]
);

if($ber) {
    my $data = $ber->buffer;

    print "ok ",$test++,"\n";

    my $result = pack("C*", 0x30, 0x10, 0x02, 0x01, 0x01, 0x01, 0x01, 0x00,
			    0x04, 0x08, 0x41, 0x20, 0x73, 0x74, 0x72, 0x69,
			    0x6E, 0x67
    );

    print "not "
	unless $ber->buffer eq $result;
    print "ok ",$test++,"\n";

    my $seq = undef;

    print "not "
	unless $ber->decode(SEQUENCE => \$seq) && $seq;

    print "ok ",$test++,"\n";

    print "not "
	unless substr($result,2) eq $seq->buffer;

    print "ok ",$test++,"\n";

    $ber = new Convert::BER($data);

    my($int,$bool,$str);

    $ber->decode(
	SEQUENCE => [
	    INTEGER => \$int,
	    BOOLEAN => \$bool,
	    STRING  => \$str,
	]
    ) && ($int == 1) && !$bool && ($str eq "A string")
	or print "not ";

    print "ok ",$test++,"\n";

    
}

print "not ok ",$test++,"\n"
	while($test <= 5);


