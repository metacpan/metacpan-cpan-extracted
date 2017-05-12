#!perl -w
use strict;
use Test::More tests => 5;

# This time, with folding!

use_ok("Data::Message");
sub read_file { local $/; local *FH; open FH, shift or die $!; return <FH> }

my $mail_text = read_file("t/test-mails/josey-fold");

my $mail = Data::Message->new($mail_text);
isa_ok($mail, "Data::Message");
is($mail->header("References"), 
   q{<200211120937.JAA28130@xoneweb.opengroup.org>  <1021112125524.ZM7503@skye.rdg.opengroup.org>  <3DD221BB.13116D47@sun.com>},
    "References header checks out");
is($mail->header("reFerEnceS"),
   q{<200211120937.JAA28130@xoneweb.opengroup.org>  <1021112125524.ZM7503@skye.rdg.opengroup.org>  <3DD221BB.13116D47@sun.com>},
    "References header checks out with case folding");
is_deeply([$mail->header("Received")],
[
'from mailman.opengroup.org ([192.153.166.9]) by deep-dark-truthful-mirror.pad with smtp (Exim 3.36 #1 (Debian)) id 18Buh5-0006Zr-00 for <posix@simon-cozens.org>; Wed, 13 Nov 2002 10:24:23 +0000',
'(qmail 1679 invoked by uid 503); 13 Nov 2002 10:10:49 -0000'],
"And the received headers are folded gracefully, and multiple headers work");
