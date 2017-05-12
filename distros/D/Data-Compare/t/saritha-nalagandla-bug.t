#!perl -w
# $Id: saritha-nalagandla-bug.t,v 1.2 2008/08/26 20:51:36 drhyde Exp $

use strict;
use Data::Compare;
eval "use JSON";
if($@) {
    eval 'use Test::More skip_all => "no JSON support";exit 0';
} elsif($JSON::VERSION < 2.9) {
    eval 'use Test::More skip_all => "JSON module too old";exit 0';
} else {
    eval 'use Test::More tests => 2';
}

my $expfile = "t/saritha-nalagandla-bug/test082_updateevent_multipleinvitees.exp";
my $outfile = "t/saritha-nalagandla-bug/test082_updateevent_multipleinvitees.out";
my $ignoreKeysList = [qw(UID INVID LAST_MODIFIED DTSTAMP_UTC BUILD)];

$/ = undef;

($expfile, $outfile) = map {
    open(FILE, $_) || die("Can't open $_\n");
    my $f = <FILE>;
    close(FILE);
    from_json($f);
} ($expfile, $outfile);

# delete $expfile->{RESPONSE}{VALUE}{ATTENDEE}[0]{RSVP};
# delete $outfile->{RESPONSE}{VALUE}{ATTENDEE}[0]{RSVP};
# delete $expfile->{RESPONSE}{VALUE}{ATTENDEE}[1]{RSVP};
# delete $outfile->{RESPONSE}{VALUE}{ATTENDEE}[1]{RSVP};

ok(Compare($expfile, $outfile, {ignore_hash_keys=> $ignoreKeysList}), "match with ignore_hash_keys");
ok(!Compare($expfile, $outfile), "doesn't match without ignore_hash_keys");
