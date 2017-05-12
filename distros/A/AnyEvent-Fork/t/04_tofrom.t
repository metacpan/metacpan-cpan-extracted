BEGIN { $| = 1; print "1..18\n"; }

BEGIN {
   $ENV{PERL_ANYEVENT_MODEL} = "Perl"; # work around bugs in win32 perls
}

use AnyEvent::Fork;

print "ok 1\n";

my $proc = new AnyEvent::Fork; print "ok 2\n";
my $to1  = new AnyEvent::Fork; print "ok 3\n";
my $to2  = new AnyEvent::Fork; print "ok 4\n";

$to1->eval ("1");

print "ok 5\n";

my $fh1 = do { $to1->to_fh (my $cv = AE::cv); $cv->recv }; print "ok 6\n";
my $fh2 = do { $to2->to_fh (my $cv = AE::cv); $cv->recv }; print "ok 7\n";

undef $to1;
undef $to2;

print $proc ? "" : "not ", "ok 8\n";

use AnyEvent::Util;

print +(my ($r1, $w1) = AnyEvent::Util::portable_pipe) ? "" : "not ", "ok 9\n";
print +(my ($r2, $w2) = AnyEvent::Util::portable_pipe) ? "" : "not ", "ok 10\n";

$proc->send_fh ($fh1); undef $fh1; $proc->send_fh ($w1); undef $w1; print "ok 11\n";
$proc->send_fh ($fh2); undef $fh2; $proc->send_fh ($w2); undef $w2; print "ok 12\n";

$proc->eval ('
   use AnyEvent;
   use AnyEvent::Fork;

   my $to1 = new_from_fh AnyEvent::Fork $arg[0]; $to1->send_fh ($arg[1]); $to1->eval ($_[0]);
   my $to2 = new_from_fh AnyEvent::Fork $arg[2]; $to2->send_fh ($arg[3]); $to2->eval ($_[1]);

   $to1->to_fh (my $cv1 = AE::cv); $cv1->recv;
   $to2->to_fh (my $cv2 = AE::cv); $cv2->recv;
','
   syswrite $arg[0], "172";
','
   syswrite $arg[0], "174";
');

print "ok 13\n";

do { $proc->to_fh (my $cv = AE::cv); $cv->recv };

print "ok 14\n";

undef $proc;

print "ok 15\n";

$r1 = <$r1>;
print $r1 eq "172" ? "" : "not ", "ok 16 # $r1\n";

$r2 = <$r2>;
print $r2 eq "174" ? "" : "not ", "ok 17 # $r2\n";

print "ok 18\n";

