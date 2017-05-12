# $Id$
use strict;
use Test::More tests => 24;

BEGIN {
    use_ok 'DateTime::Format::Mail';
}

my $f = DateTime::Format::Mail->new->loose;

$SIG{__WARN__} = sub { die };

while (<DATA>)
{
    chomp;
    my $p = eval { $f->parse_datetime( $_ ) };
    ok(
        (
            !(defined $p and ref $p and not $@)
                and ( $@ =~ /^Invalid format / )
        ),
        "Could not parse invalid date: $_" );
}

pass("Didn't crash and burn!")

__DATA__
Fri, 11 Mar 83 07:19:39 GTB Standart Saati
Fri, 18 Oct 02 11:19:41 Eastern Daylight Time
Fri, 20 Dec 2002 17:05:41 +0100 (West-Europa (standaardtijd))
lun, 20 ene 2003 04:25:57
Mon, 11 Nov 2002 18:03:25 +50578934
Mon, 24 Feb 03 05:20:51 Central Standard Time
Mon, 24 Feb 03 13:40:52 Central Standard Time
Sunday , 23 Feb 2003 05:38:27 PM
Thu, 20 Feb 2003 14:10:12 PST -0800
Thu, Jul 6 2000 15:13:49 GMT-0400
Thu, Jul 6 2000 15:23:41 GMT-0400
Tue, 18 Jun 102 11:37:08 EDT
Tue, 18 Jun 102 13:12:32 EDT
Tue, 24 Sep 2002 00:56:10 +1:0
Tue, Jul 11 2000 19:05:28 GMT-0400
Tue, Jul 11 2000 19:24:48 GMT-0400
Tuesday, January 14, 2003  9:35 AM
Wed, 09 Mar 83 14:53:09 GTB Standart Saati
Wed, 12 Feb 103 11:20:24 -0500 (EST)
Wed, 13 Nov 2002 11:23:07 +50578934
Wed, 18 Sep 2002 10:04:15 %z (CDT)
Wed Mar  5 04:59:12 CST 2003
