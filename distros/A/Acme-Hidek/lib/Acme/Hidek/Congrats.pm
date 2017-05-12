package Acme::Hidek::Congrats;
use strict;
use warnings;

my $package = __PACKAGE__;

my $tie = "WE LOVE HIDEK!\n\n";

my @messages = (
    'Happy birthday,',
    'Happy 40th birthday,',
    'Congrats',
    'Congrats on your birthday,',
    'Congrats on your 40th birthday,',
    'Congratulations,',
    'Congratulations on your birthday,',
    'Congratulations on your 40th birthday,',
    'Hearty congratulations,',
    'Hearty congratulations on your birthday,',
    'Hearty congratulations on your 40th birthday,',
    'Heartiest congratulations,',
    'Heartiest congratulations on your birthday,',
    'Heartiest congratulations on your 40th birthday,',
);

sub whiten {
    local $_ = unpack "b*", pop;
    s/0/"$messages[rand @messages] hidek!\n\n"/ge;
    s/1/"$messages[rand @messages] Hidek!\n\n"/ge;
    $tie.$_;
}
sub brighten {
    local $_ = pop;
    s/^\Q$tie\E//xmsg;
    s/\d//g;
    s/\b hidek \b/0/xmsg;
    s/\b Hidek \b/1/xmsg;
    s/[^01]//g;
    pack "b*", $_;
}

sub dress { $_[0] =~ /^$tie/ }

open my $in, '<', $0 or print "Can't rebleach '$0'\n" and exit;

(my $shirt = join "", <$in>) =~ s/.* ^ \s* use \s+ \Q$package\E \s* ; \n //xms;

do { eval brighten $shirt; $@ && die; exit } unless not dress $shirt;

open my $out, '>', "${0}c" or print "Cannot bleach '${0}c'\n" and exit;
print {$out} "use $package;\n", whiten $shirt;
