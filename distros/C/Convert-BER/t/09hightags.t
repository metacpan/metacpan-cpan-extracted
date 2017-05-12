#!/usr/local/bin/perl

#
# Test that high tag values (greater than 30) work
#


use lib "/l/dbi";

use Convert::BER 1.31 qw(/BER/ ber_tag);


print "1..213\n";

$tcount = $test = 1;

sub test (&) {
    my $sub = shift;
    eval { $sub->() };
    ## print "# $@" if $@;

    print "not ok ",$test++," # skipped\n"
        while($test < $tcount);

    warn "count mismatch test=$test tcount=$tcount"
	unless $test == $tcount;

    $tcount = $test;
}




##
## IMPLICIT TAG, inline
##

@TAGS = (# Value                          Bytes in tag
         ###################################################
         [ber_tag(0,38),                  0x1f, 0x26],
         [ber_tag(BER_CONTEXT,39),        0x9f, 0x27],
         [ber_tag(BER_APPLICATION,40),    0x5f, 0x28],
         [ber_tag(BER_UNIVERSAL,41),      0x1f, 0x29],
         [ber_tag(BER_PRIVATE,42),        0xdf, 0x2a],
         [ber_tag(BER_PRIMITIVE,43),      0x1f, 0x2b], 
         [ber_tag(BER_CONSTRUCTOR,44),    0x3f, 0x2c], 
         
         [ber_tag(0,0x138),               0x1f, 0x82, 0x38],
         [ber_tag(BER_CONTEXT,0x139),     0x9f, 0x82, 0x39],
         [ber_tag(BER_APPLICATION,0x140), 0x5f, 0x82, 0x40],
         [ber_tag(BER_UNIVERSAL,0x141),   0x1f, 0x82, 0x41],
         [ber_tag(BER_PRIVATE,0x142),     0xdf, 0x82, 0x42],
         [ber_tag(BER_PRIMITIVE,0x143),   0x1f, 0x82, 0x43],
         [ber_tag(BER_CONSTRUCTOR,0x144), 0x3f, 0x82, 0x44],
         
         [ber_tag(BER_CONTEXT | BER_CONSTRUCTOR, 1), 0xa1],
         );

# [type, value, length and value bytes].
@VALUES = ([STRING => "A string",
            0x08, 0x41, 0x20, 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67],
           
           [SEQUENCE => [INTEGER => 1, BOOLEAN => 0, STRING => "A string",],
            0x10, # length
            0x02, 0x01, 0x01, # integer 
            0x01, 0x01, 0x00, # boolean
            0x04, 0x08, 0x41, 0x20, 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67 # string
            ],
           );

foreach $tagref (@TAGS) {
    my ($tag, @tag) = @$tagref;

    foreach $valref (@VALUES) {
        my ($type, $val, @result) = @$valref;
        printf "# [$type => 0x%x] => %s\n", $tag, (ref $val) ? "@$val" : $val;
        
        $tcount += 6;
        
        test {
            my $ber = Convert::BER->new->encode([$type=>$tag] => $val) or die;

                print "ok ",$test++,"\n";

            die "Bad tag value" unless $ber->tag() == $tag;

                print "ok ",$test++,"\n";

            my $result = pack("C*", @tag, @result);
            die "Bad result" unless $ber->buffer eq $result;

	        print "ok ",$test++,"\n";

            if ("STRING" eq $type) {
                my $str = undef;
                $ber->decode( [ $type => $tag ] => \$str) or die;

                    print "ok ",$test++,"\n";

                die "Defined" unless defined($str);

                    print "ok ",$test++,"\n";

                die "Equal" unless ($str eq $val);

                    print "ok ",$test++,"\n";
            }
            elsif ("SEQUENCE" eq $type) {
                my ($int, $bool, $str) = (undef, undef, undef);
                $ber->decode(
                    [ $type => $tag ] => [
                        INTEGER => \$int,
                        BOOLEAN => \$bool,
                        STRING  => \$str,
                
                    ] 
                ) or die;

                    print "ok ",$test++,"\n";

                die "Defined"
                    unless defined($str) && defined($int) && defined($bool);

                    print "ok ",$test++,"\n";

                die "Equal" 
                    unless ($str eq "A string") && ($int==1) && ($bool==0);

                    print "ok ",$test++,"\n";
            }
        }
    }
}

##
## IMPLICIT TAG, subclass
##

package Test::BER;

use Convert::BER qw(/BER_/ /^\$/ ber_tag);

@ISA = qw(Convert::BER);

Test::BER->define(

  # Name          Type          Tag
  ########################################

  [ SUB_STRING => $STRING,
   ber_tag(BER_CONTEXT | BER_PRIMITIVE, 0x101) ],

  [ SUB_SEQ    => $SEQUENCE,    
   ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, 0x300) ],

  [ SUB_SEQ_OF => $SEQUENCE_OF, 
   ber_tag(BER_APPLICATION | BER_CONSTRUCTOR, 0x36) ],
                  
);


package main;

##
## SUB_STRING
##

my %STRING = (
    ""		=> pack("C*",   0x9F, 0x82, 0x01, 0x00),
    "A string"	=> pack("CCCCa*", 0x9F, 0x82, 0x01, 0x08, "A string"),
);

while(($val,$result) = each %STRING) {
    print "# SUB_STRING '$val'\n";

    $tcount += 5;
    test {
        my $ber = Test::BER->new->encode( SUB_STRING => $val) or die;

	    print "ok ",$test++,"\n";

	die unless $ber->buffer eq $result;

	    print "ok ",$test++,"\n";

	my $str = undef;

	die unless $ber->decode( SUB_STRING => \$str);

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

    my $result = pack("C*", 0x7F, 0x86, 0x00, # tag
                      0x10, # length
                      0x02, 0x01, 0x01, # integer 
                      0x01, 0x01, 0x00, # boolean
                      0x04, 0x08, 0x41, 0x20, 0x73, 0x74, 0x72, 0x69, 
                      0x6E, 0x67
    );

    die unless $ber->buffer eq $result;

	print "ok ",$test++,"\n";

    my $seq = undef;
    die unless $ber->decode(SUB_SEQ => \$seq) && $seq;

	print "ok ",$test++,"\n";

    die unless substr($result,4) eq $seq->buffer;

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
    my $ber = Test::BER->new->encode(
	    SUB_SEQ_OF => [ 4,
		INTEGER => 1
	    ]) or die;

	print "ok ",$test++,"\n";

    $result = pack("C*", 0x7F, 0x36, # tag
                   0x0C, # length
                   0x02, 0x01, 0x01, 0x02, 0x01, 0x01,
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



##
## EXPLICIT TAG
##


@ETAGS = (
          ber_tag(BER_CONTEXT | BER_CONSTRUCTOR, 40), 
          ber_tag(BER_CONTEXT | BER_CONSTRUCTOR, 140), 
          ber_tag(BER_CONTEXT | BER_CONSTRUCTOR, 1140), 
          ber_tag(BER_CONTEXT | BER_CONSTRUCTOR, 11140), 
          );

foreach $tag (@ETAGS) {
    printf "# EXTENDED TAG 0x%x\n", $tag;

    $tcount += 3;
    test {
        my $ber = Convert::BER->new->encode(
                      SEQUENCE => [
                          [ SEQUENCE => $tag ] => [ INTEGER => 10 ],
                            INTEGER => 11,
                          ] 
                  ) or die;

            print "ok ", $test++, "\n";

        my ($i1, $i2) = (undef, undef);
        $ber->decode(SEQUENCE => [ 
                          [SEQUENCE => $tag]  => [INTEGER => \$i1],
                           INTEGER => \$i2
                     ]) 
            or die;

            print "ok ", $test++, "\n";

        die unless $i1 == 10 && $i2 == 11;
        
            print "ok ", $test++, "\n";
    }
}
