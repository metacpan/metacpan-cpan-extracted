#!/usr/bin/perl -sw
##
## 11-wrapper.t
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 11-wrapper.t,v 1.2 2001/04/17 19:53:23 vipul Exp $

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crypt::RSA;
use Crypt::RSA::Debug qw(debuglevel);

print "1..12\n";
my $i = 0;
my $rsa = new Crypt::RSA;

my $plaintext =<<'EOM';
   "They met me in the day of success, and I have
    learned by the perfectest report they have more in them than
    mortal knowledge. When I burned in desire to question them
    further, they made themselves air, into which they vanished.

    Whiles I stood rapt in the wonder of it, came missives from the
    King, who all-hailed me 'Thane of Cawdor'; by which title,
    before, these weird sisters saluted me and referred me to the
    coming on of time with 'Hail, King that shalt be!' This have I
    thought good to deliver thee, my dearest partner of greatness,
    that thou mightst not lose the dues of rejoicing, by being
    ignorant of what greatness is promised thee. Lay it to thy heart,
    and farewell.

    Glamis thou art, and Cawdor, and shalt be
    What thou art promised. Yet do I fear thy nature.
    It is too full o' the milk of human kindness
    To catch the nearest way. Thou wouldst be great; 
    Art not without ambition, but without
    The illness should attend it. What thou wouldst highly,
    That wouldst thou holily; wouldst not play false,
    And yet wouldst wrongly win. Thou'ldst have, great Glamis,
    That which cries, "Thus thou must do, if thou have it;
    And that which rather thou dost fear to do
    Than wishest should be undone." Hie thee hither,
    That I may pour my spirits in thine ear,
    And chastise with the valor of my tongue
    All that impedes thee from the golden round,
    Which fate and metaphysical aid doth seem
    To have thee crown'd withal."

EOM

for my $keysize (qw(384 1536 512)) { 

    # $plaintext = "" if $keysize == 512;

    my ($pub, $pri) = $rsa->keygen ( 
                        Size      => $keysize, 
                        Verbosity => 1, 
                        Identity  => "Lord Macbeth",
                        Password  => "xx"
                      ) or die $rsa->errstr();

    my $ctxt = $rsa->encrypt ( 
                        Message => $plaintext,
                        Key     => $pub,
                        Armour  => 1,
                     ) || die $rsa->errstr();

    print "$ctxt\n";

    print $ctxt ? "ok" : "not ok"; print " ", ++$i, "\n";

    my $ptxt = $rsa->decrypt (
                        Cyphertext => $ctxt, 
                        Key        => $pri,
                        Armour     => 1, 
                     );

    die $rsa->errstr() if ($rsa->errstr() && !$ptxt);

    print $ptxt if $ptxt;
    print $ptxt eq $plaintext  ? "ok" : "not ok"; print " ", ++$i, "\n";

    my $signature = $rsa->sign ( 
                        Message => $plaintext, 
                        Key => $pri,
                        Armour => 1,
                    ) || die $rsa->errstr();

    print "$signature\n";
    print $signature ? "ok" : "not ok"; print " ", ++$i, "\n";

    my $verify = $rsa->verify (
                    Message => $plaintext, 
                    Key => $pub, 
                    Signature => $signature,
                    Armour => 1,
                 );

    print $verify ? "ok" : "not ok"; print " ", ++$i, "\n";

}
