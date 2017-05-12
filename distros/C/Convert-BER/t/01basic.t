#!/usr/local/bin/perl

#
# Test that the primitive operators are working
#

use Convert::BER;

print "1..19\n";

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
## Test array tags
##

$tcount += 4;
test {
    my $ber = Convert::BER->new->encode( [ NULL, 0x35 ] => 0 ) or die;

	print "ok ",$test++,"\n";

    my $result = pack("C*", 0x35, 0x00);

    die unless $ber->buffer eq $result;

	print "ok ",$test++,"\n";

    my $null;

    $ber->decode( [ NULL, 0x35 ] => \$null) or die;

	print "ok ",$test++,"\n";

    die unless $null;

	print "ok ",$test++,"\n";
};

##
## Test array ref value
##

$tcount += 5;
test {

    my $ber = Convert::BER->new->encode( STRING => [qw(two strings)] );

    die unless $ber;

    	print "ok ",$test++,"\n";

    my $result = pack("C*", 0x04, 0x03, 0x74, 0x77, 0x6F, 0x04, 0x07, 0x73,
			    0x74, 0x72, 0x69, 0x6E, 0x67, 0x73);

    die unless $ber->buffer eq $result;

    	print "ok ",$test++,"\n";

    my @str = ();

    $ber->decode( STRING => \@str) or die;

    	print "ok ",$test++,"\n";

    die unless @str == 2;

    	print "ok ",$test++,"\n";

    die unless join("~",@str) eq "two~strings";

    	print "ok ",$test++,"\n";
};

##
## Test sub returning value
##

$tcount += 4;
test {

    my $ber = Convert::BER->new->encode( INTEGER => sub { 0xABCDEF } );

    die unless $ber;

    	print "ok ",$test++,"\n";

    my $result = pack("C*", 0x02, 0x04, 0x00, 0xAB, 0xCD, 0xEF);

    die unless $ber->buffer eq $result;

    	print "ok ",$test++,"\n";

    my $int;

    $ber->decode( INTEGER => \$int) or die;

    	print "ok ",$test++,"\n";

    die unless $int == 0xABCDEF;

    	print "ok ",$test++,"\n";

};

##
## Test sub returning array ref value
##

$tcount += 6;
test {

    my $ber = Convert::BER->new->encode( ENUM => sub { [ 0xFEDCBA, -96 ] } );

    die unless $ber;

    	print "ok ",$test++,"\n";

    my $result = pack("C*", 0x0A, 0x04, 0x00, 0xFE, 0xDC,
			    0xBA, 0x0A, 0x01, 0xA0);

    die unless $ber->buffer eq $result;

    	print "ok ",$test++,"\n";

    my @int = ();

    $ber->decode( ENUM => \@int) or die;

    	print "ok ",$test++,"\n";

    die unless @int == 2;

    	print "ok ",$test++,"\n";

    die unless $int[0] == 0xFEDCBA;

    	print "ok ",$test++,"\n";

    die unless $int[1] == -96;

    	print "ok ",$test++,"\n";
};
