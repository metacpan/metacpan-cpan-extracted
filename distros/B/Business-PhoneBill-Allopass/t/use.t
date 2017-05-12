#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 2 }

use Business::PhoneBill::Allopass;
my $session_file='apsession.tmp';

my $allopass=''; $allopass=Business::PhoneBill::Allopass->new($session_file);
if (ref $allopass){
    ok(1);
} else {
    ok(0);
}


ok(unlink($session_file));

exit;
__END__