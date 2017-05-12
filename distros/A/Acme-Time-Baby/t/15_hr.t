# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN {
    if ($] eq '5.009005') {
        print "1..1\n";
        print "# This is for silly CPAN testers running 5.9.5.\n";
        print "ok 1\n";
        exit;
    }
}

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use strict;
BEGIN { plan tests => 1 + 24 * 60 };
use Acme::Time::Baby language => 'hr';
ok(1); # If we made it this far, we're ok.

#########################

my $i = 0;
my %numbers = map {$_ => ++$i} split ' ' =>
                   qq /jedan dva tri \x{010d}etiri pet \x{0161}est sedam
                       osam devet deset jedanaest dvanaest/;

foreach my $hours (1 .. 24) {
    foreach my $minutes (0 .. 59) {
        my $r = babytime "$hours:$minutes";
        my ($big)    = $r =~ /Velika kazaljka pokazuje (\S+)/;
        my ($little) = $r =~ /mala kazaljka pokazuje (\S+)/;

        if (!defined $big || !defined $little) {
            ok (0);
            print ("# cannot match big or little in $hours:$minutes -> $r\n");
            next
        }

        my $ok = 1;

        $big    = $numbers {$big}    and
        $little = $numbers {$little} or do {
            ok (0);
            print ("# matching $hours:$minutes -> $r\n");
            next
        };

           if ($minutes < 3)            {$ok = 0 unless $big == 12;}
        elsif ($minutes < $big * 5 - 2) {$ok = 0;}
        elsif ($minutes > $big * 5 + 2) {$ok = 0;}

        my $h   = $hours;
           $h  += 1 if $minutes > 30;
           $h  %= 12;
           $h ||= 12;

        $ok = 0 if $h != $little;

        ok ($ok);
        unless ($ok) {
	    print "# $hours:$minutes -> $r\n";
        }
    }
}
