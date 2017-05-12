#!/usr/local/bin/perl

BEGIN {
  if ($] >= 5.006) {
    require bytes; 'bytes'->import;
  }
}

#
# Test that the primitive operators are working
#

use Convert::BER;

print "1..90\n";

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
## Assumptions. I assume perl truncates values for me, check them
##

$tcount += 6;
test {
    my $tag = 0x31323334;

    print "not " unless chr($tag) eq "4";
    	print "ok ",$test++,"\n";

    print "not " unless pack("n",$tag) eq "34";
    	print "ok ",$test++,"\n";

    print "not " unless pack("nc",$tag>>8,$tag) eq "234";
    	print "ok ",$test++,"\n";

    $tag = 0x81828384;

    print "not " unless ord(chr($tag)) == 0x84;
    	print "ok ",$test++,"\n";

    print "not " unless pack("n",$tag) eq pack("C*",0x83,0x84);
    	print "ok ",$test++,"\n";

    print "not " unless pack("nc",$tag>>8,$tag)  eq pack("C*",0x82,0x83,0x84);
    	print "ok ",$test++,"\n";
};

##
## NULL
##

$tcount += 4;
test {
    print "# NULL\n";

    $ber = Convert::BER->new->encode( NULL => 0 ) or die;

    	print "ok ",$test++,"\n";

    my $result = pack("C*", 0x05, 0x00);

    die unless $ber->buffer eq $result;

	print "ok ",$test++,"\n";

    my $null = undef;

    $ber->decode(NULL => \$null) or die;

	print "ok ",$test++,"\n";

    die unless $null;

	print "ok ",$test++,"\n";
};

##
## BOOLEAN (tests 4 - 12)
##

foreach $val (0,1,-99) {
    print "# BOOLEAN $val\n";

    $tcount += 5;
    test {
        my $ber = Convert::BER->new->encode( BOOLEAN => $val) or die;

	    print "ok ",$test++,"\n";

	my $result = pack("C*", 0x01, 0x01, $val ? 0xFF : 0);

	die unless $ber->buffer eq $result;

	    print "ok ",$test++,"\n";

	my $bool = undef;

	die unless $ber->decode( BOOLEAN => \$bool);

	    print "ok ",$test++,"\n";

	die unless defined($bool);

	    print "ok ",$test++,"\n";

	die unless(!$bool == !$val);

	    print "ok ",$test++,"\n";
    };
}

##
## INTEGER (tests 13 - 21)
##

my %INTEGER = (
    0		=> pack("C*", 0x02, 0x01, 0x00),
    0x667799	=> pack("C*", 0x02, 0x03, 0x66, 0x77, 0x99),
    -457	=> pack("C*", 0x02, 0x02, 0xFE, 0x37),
);

while(($v,$result) = each %INTEGER) {
    $val = eval($v);
    print "# INTEGER $val\n";

    $tcount += 5;

    test {
        my $ber = Convert::BER->new->encode( INTEGER => $val) or die;

	    print "ok ",$test++,"\n";

	die unless $ber->buffer eq $result;

	    print "ok ",$test++,"\n";

	my $int = undef;

	die unless $ber->decode( INTEGER => \$int);

	    print "ok ",$test++,"\n";

	die unless defined($int);

	    print "ok ",$test++,"\n";

	die unless ($int == $val);

	    print "ok ",$test++,"\n";
    }
}

##
## STRING
##

my %STRING = (
    ""		=> pack("C*",   0x04, 0x00),
    "A string"	=> pack("CCa*", 0x04, 0x08, "A string"),
);

while(($val,$result) = each %STRING) {
    print "# STRING '$val'\n";

    $tcount += 5;
    test {
        my $ber = Convert::BER->new->encode( STRING => $val) or die;

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
## OBJECT_ID
##

my %OBJECT_ID = (
    "1.2.3.4.5" => pack("C*", 0x06, 0x04, 0x2A, 0x03, 0x04, 0x05),
    "2.5.457"   => pack("C*", 0x06, 0x03, 0x55, 0x83, 0x49),
);


while(($val,$result) = each %OBJECT_ID) {
    print "# OBJECT_ID $val\n";

    $tcount += 5;

    test {
        my $ber = Convert::BER->new->encode( OBJECT_ID => $val) or die;

	    print "ok ",$test++,"\n";

	die unless $ber->buffer eq $result;

	    print "ok ",$test++,"\n";

	my $oid = undef;

	die unless $ber->decode( OBJECT_ID => \$oid);

	    print "ok ",$test++,"\n";

	die unless defined($oid);

	    print "ok ",$test++,"\n";

	die unless ($oid eq $val);

	    print "ok ",$test++,"\n";
    }
}

##
## ENUM
##

my %ENUM = (
    0		=> pack("C*", 0x0A, 0x01, 0x00),
    -99		=> pack("C*", 0x0A, 0x01, 0x9D),
    6573456	=> pack("C*", 0x0A, 0x03, 0x64, 0x4D, 0x90),
);

while(($v,$result) = each %ENUM) {
    $val = eval($v);
    print "# ENUM $val\n";

    $tcount += 5;

    test {
        my $ber = Convert::BER->new->encode( ENUM => $val) or die;

	    print "ok ",$test++,"\n";

	die unless $ber->buffer eq $result;

	    print "ok ",$test++,"\n";

	my $enum = undef;

	die unless $ber->decode( ENUM => \$enum);

	    print "ok ",$test++,"\n";

	die unless defined($enum);

	    print "ok ",$test++,"\n";

	die unless ($enum == $val);

	    print "ok ",$test++,"\n";
    }
}

##
## BIT STRING
##

my %BSTR = (
    '0'		=> pack("C*", 0x03, 0x02, 0x07, 0x00),
    '00110011'	=> pack("C*", 0x03, 0x02, 0x00, 0x33),
    '011011100101110111'
		=> pack("C*", 0x03, 0x04, 0x06, 0x6E, 0x5D, 0xC0),
);

while(($val,$result) = each %BSTR) {
    print "# BIT STRING $val\n";

    $tcount += 5;

    test {
        my $ber = Convert::BER->new->encode( BIT_STRING => $val) or die;

	    print "ok ",$test++,"\n";

	die unless $ber->buffer eq $result;

	    print "ok ",$test++,"\n";

	my $bstr = undef;

	die unless $ber->decode( BIT_STRING => \$bstr);

	    print "ok ",$test++,"\n";

	die unless defined($bstr);

	    print "ok ",$test++,"\n";

	die unless ($bstr eq $val);

	    print "ok ",$test++,"\n";
    }
}
