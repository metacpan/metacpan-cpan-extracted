#!/usr/local/bin/perl

#
# Test that the primitive operators are working
#

use Convert::BER;

print "1..6\n"; # This testcase needs more tests

$tcount = $test = 1;

sub test (&) {
    my $sub = shift;
    eval { $sub->() };

    print "not ok ",$test++,"\n"
        while($test < $tcount);

    warn "count mismatch test=$test tcount=$tcount"
	unless $test == $tcount;

    $tcount = $test;
}

##
## Test building optional
##

$tcount += 4;
test {
    my $ber = Convert::BER->new->encode( OPTIONAL => [ INTEGER => 0x35 ] ) or die;

	print "ok ",$test++,"\n";

    my $result = pack("C*", 0x02, 0x01, 0x35);

    die $ber->hexdump unless $ber->buffer eq $result;

	print "ok ",$test++,"\n";

    my $int;

    $ber->decode( OPTIONAL => [ INTEGER => \$int ]) or die;

	print "ok ",$test++,"\n";

    die unless $int == 0x35;

	print "ok ",$test++,"\n";
};

$tcount += 2;
test {
    my $ber = Convert::BER->new->encode( OPTIONAL => [ INTEGER => undef ] ) or die;

	print "ok ",$test++,"\n";

    my $result = "";

    die $ber->dump unless $ber->buffer eq $result;

	print "ok ",$test++,"\n";
};
