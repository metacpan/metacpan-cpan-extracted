#!/usr/local/bin/perl

#
# Test that sub-classing of Convert::BER works
#

use Convert::BER;

package Test::BER;

use Convert::BER qw(/BER_/ /^\$/);

@ISA = qw(Convert::BER);

Test::BER->define(

  # Name		Type      Tag
  ########################################

  [ SUB_STRING	      => $STRING,      undef ],

  [ SUB_SEQ           => $SEQUENCE,    BER_APPLICATION | BER_CONSTRUCTOR | 0x00 ],
  [ SUB_SEQ_OF	      => $SEQUENCE_OF, BER_APPLICATION | BER_CONSTRUCTOR | 0x06 ],
);

package main;

print "1..21\n";

$tcount = $test = 1;

sub test (&) {
    my $sub = shift;
    eval { $sub->() };

    print "not ok ",$test++," # skipped\n"
        while($test < $tcount);

    warn "count mismatch test=$test tcount=$tcount"
	unless $test == $tcount;

    $tcount = $test;
}

##
## SUB_STRING
##

my %STRING = (
    ""		=> pack("C*",   0x04, 0x00),
    "A string"	=> pack("CCa*", 0x04, 0x08, "A string"),
);

while(($val,$result) = each %STRING) {
    print "# STRING '$val'\n";

    $tcount += 5;
    test {
        my $ber = Test::BER->new->encode( SUB_STRING => $val) or die;

	    print "ok ",$test++,"\n";

	die unless $ber->buffer eq $result;

	    print "ok ",$test++,"\n";

	my $str = undef;

	die unless $ber->decode( STRING => \$str);

	    print "ok ",$test++,"\n";

	die unless defined($str);

	    print "ok ",$test++,"\n";

	die unless ($str eq $val);

	    print "ok ",$test++,"\n";
    }
}

##
## SUB_SEQ
##
    print "# SUB_SEQ\n";

$tcount += 6;
test {
    my $ber = Test::BER->new->encode(
	SUB_SEQ => [
	    INTEGER => 1,
	    BOOLEAN => 0,
	    STRING => "A string"
	]
    ) or die;

    my $data = $ber->buffer;

	print "ok ",$test++,"\n";

    my $result = pack("C*", 0x60, 0x10, 0x02, 0x01, 0x01, 0x01, 0x01, 0x00,
			    0x04, 0x08, 0x41, 0x20, 0x73, 0x74, 0x72, 0x69,
			    0x6E, 0x67
    );

    die unless $ber->buffer eq $result;

	print "ok ",$test++,"\n";

    my $seq = undef;

    die unless $ber->decode(SUB_SEQ => \$seq) && $seq;

	print "ok ",$test++,"\n";

    die unless substr($result,2) eq $seq->buffer;

	print "ok ",$test++,"\n";

    $ber = new Test::BER($data) or die;

	print "ok ",$test++,"\n";

    my($int,$bool,$str);

    $ber->decode(
	SUB_SEQ => [
	    INTEGER => \$int,
	    BOOLEAN => \$bool,
	    STRING  => \$str,
	]
    ) && ($int == 1) && !$bool && ($str eq "A string")
	or die;

	print "ok ",$test++,"\n";
    
};


##
## SUB_SEQ_OF
##

$tcount += 5;
    print "# SUB_SEQ_OF\n";
test {
    $ber = Test::BER->new->encode(
	    SUB_SEQ_OF => [ 4,
		INTEGER => 1
	    ]) or die;

	print "ok ",$test++,"\n";

    $result = pack("C*", 0x66, 0x0C, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01,
			 0x02, 0x01, 0x01, 0x02, 0x01, 0x01);

    die unless $ber->buffer eq $result;

	print "ok ",$test++,"\n";

    my $i;
    my $count;

    $ber->decode(
	SUB_SEQ_OF => [ \$count,
	    INTEGER => \$i
	]
    ) or die;

	print "ok ",$test++,"\n";

    die unless $i == 1;

	print "ok ",$test++,"\n";

    die unless $count == 4;

	print "ok ",$test++,"\n";
};
