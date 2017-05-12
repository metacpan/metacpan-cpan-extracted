use Test::More tests => 30;

use strict;
use warnings;

use Dancer qw(:tests);
use Dancer::Plugin::Passphrase;

my $secret = "Super Secret Squirrel";

# Test a bunch of bcyrpt hashes generated from other places

# From v1.0.0 of Dancer::Plugin::Passphrase. Perl 5.14.2, OS X 10.8.2
my @old_dpp_version = qw(
    {CRYPT}$2a$04$utiZ69Z.1fRZZmxNjLRv/eLyPUzWLRaCO26OB/HsbyvZ4dReU.ct6
    {CRYPT}$2a$04$x9.J131nELn13EYvG2b.DuE4J.Z36wUaf1n9zfT91wloa/Nn5BbQ.
    {CRYPT}$2a$04$8g0azf0s7lyNdnMHF0WQCO1q2Wt1tCdMOecTN46.n2iyOmsW9WKqq
    {CRYPT}$2a$04$c2l3u0gkT7nbKDX4ZoaPQuGetzOtpBUilv8U5UTCphdLbuL/JsbuC
    {CRYPT}$2a$04$1VmfVtTUto/vo3YXOnN7hOpgC1pm4hSwobSrmYijPR25czhOv7pWS
    {CRYPT}$2a$04$wZwWOWvxOudBpbaC6tG0h.QC8TyNsfK.7mnoJXCvEb/PEPr/28Qji
    {CRYPT}$2a$04$dgOLegmH50m5LzkU27BKkOkHtx4ov2MW4SlhV370y7/FOzQRpB0IK
    {CRYPT}$2a$04$LW2wzn2JmwwXvwKbztxwoeWE/1RKyXLSVHH4sgAb8bRO6200c.0t.
    {CRYPT}$2a$04$4WacfXK9Dle2lx2IhCi0MuL2TNgRUrXvC2BRxs.yNmb.e.3oS4EZW
    {CRYPT}$2a$04$LCAxXIiEjzd4ttw/fLw1FOvBy6BK8pG/5PccAiOdVD5adWBwq1Jw.    
);


# From 0.008 of Authen::Passphrase::BlowfishCrypt. Perl 5.14.2, OS X 10.8.2
my @authen_passphrase = qw(
    {CRYPT}$2a$04$utiZ69Z.1fRZZmxNjLRv/eLyPUzWLRaCO26OB/HsbyvZ4dReU.ct6
    {CRYPT}$2a$04$x9.J131nELn13EYvG2b.DuE4J.Z36wUaf1n9zfT91wloa/Nn5BbQ.
    {CRYPT}$2a$04$8g0azf0s7lyNdnMHF0WQCO1q2Wt1tCdMOecTN46.n2iyOmsW9WKqq
    {CRYPT}$2a$04$c2l3u0gkT7nbKDX4ZoaPQuGetzOtpBUilv8U5UTCphdLbuL/JsbuC
    {CRYPT}$2a$04$1VmfVtTUto/vo3YXOnN7hOpgC1pm4hSwobSrmYijPR25czhOv7pWS
    {CRYPT}$2a$04$wZwWOWvxOudBpbaC6tG0h.QC8TyNsfK.7mnoJXCvEb/PEPr/28Qji
    {CRYPT}$2a$04$dgOLegmH50m5LzkU27BKkOkHtx4ov2MW4SlhV370y7/FOzQRpB0IK
    {CRYPT}$2a$04$LW2wzn2JmwwXvwKbztxwoeWE/1RKyXLSVHH4sgAb8bRO6200c.0t.
    {CRYPT}$2a$04$4WacfXK9Dle2lx2IhCi0MuL2TNgRUrXvC2BRxs.yNmb.e.3oS4EZW
    {CRYPT}$2a$04$LCAxXIiEjzd4ttw/fLw1FOvBy6BK8pG/5PccAiOdVD5adWBwq1Jw.    
);


# From v3.0.1 of the bcrypt_ruby gem. Ruby 1.9.3p125, OS X 10.8.2
my @rubygems = qw(
    {CRYPT}$2a$04$1JI5Ldcddt9.NruLgsB2cetbHwLrvD5ZsDZO6r/jZKcDc3aRkV8ny
    {CRYPT}$2a$04$GWNNixiHf63wc.6.Ebrrb.vci5HKNhd2.DMXAS5XZcbLSPUdIwjfe
    {CRYPT}$2a$04$wcvVw7eMULQ0moXOYhSOkeGdJ6MDlegt1/rnVcwP/D6Bg8G2kbY72
    {CRYPT}$2a$04$rtbeTZqiL8E3053U6yKkCOd.9UJ.ITsHjk3zA8mXdTUywXygAik82
    {CRYPT}$2a$04$K1DolOJ1aJSpTzVnhCAIU.aCHO6ohdBMA39QyiEAbINQzN7cPBPCa
    {CRYPT}$2a$04$yIPpoJ6r8Nm1cO0PTyTbzu8A8XHSUMC8/5CPmUG.jqiet9jhBjHIC
    {CRYPT}$2a$04$E1wjvpG6ykfDqArV107DY.DoVGO8dBJSM03kyaBJjQdv98BEON0jq
    {CRYPT}$2a$04$ZCwnOt5DQQ4yhhH7.iwH/unAnxHWt.e0ZGuZgcrNi7QQQlS7Enk/m
    {CRYPT}$2a$04$yr17B8vIkiVilVDn49rE.uWL0p6a2x5gI/GcoojvYhTetVQQc5jOm
    {CRYPT}$2a$04$oacLS1vbH0qh8XFEJmImLuy9sP8tgM74iah1bbY26kIgmDxTgDgSq
);


# The actual tests
for my $rfc2307 (@old_dpp_version) {
    ok(passphrase($secret)->matches($rfc2307), "Old Dancer::Plugin::Passphrase Bcrypt hashes can be validated");
}

for my $rfc2307 (@authen_passphrase) {
    ok(passphrase($secret)->matches($rfc2307), "Authen::Passphrase Bcrypt hashes can be validated");
}

for my $rfc2307 (@rubygems) {
    ok(passphrase($secret)->matches($rfc2307), "Ruby Bcrypt hashes can be validated");
}




