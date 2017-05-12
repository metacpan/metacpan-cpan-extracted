# $Id$
use strict;
use Test::More tests => 10;
use DateTime;

BEGIN {
    use_ok 'DateTime::Format::Mail';
}

my $class = 'DateTime::Format::Mail';

# Can we parse?

my $f = $class->new()->loose();
my $dt = DateTime->now->set_time_zone( 'Australia/Sydney' );

my $s = $f->format_datetime($dt);
my $p = $f->parse_datetime($s);
my $t = $f->format_datetime($p);

is( $s => $t, "Clean is same as parse/format." );

while (<DATA>)
{
    chomp;
    my ($s, $e) = split /\s*\t\s*/, $_;
    $e ||= $s;
    my $p = $f->format_datetime($f->parse_datetime($s));
    is $p => $e, $s;
}



__DATA__
Wed, 12 Mar 2003 03:22:58 +0100
Wed, 12 Mar 2003 03:22:58 MDT	Wed, 12 Mar 2003 03:22:58 -0600
Wed, 12 Mar 2003 03:22:58 Z	Wed, 12 Mar 2003 03:22:58 -0000
Wed, 12 Mar 2003 03:22:58 J	Wed, 12 Mar 2003 03:22:58 -0000
Wed, 12 Mar 2003 03:22:58 AEST	Wed, 12 Mar 2003 03:22:58 -0000
Wed, 12 Mar 03 03:22:58 -0500	Wed, 12 Mar 2003 03:22:58 -0500
01 Feb 2002 16:06:38 -0500	Fri,  1 Feb 2002 16:06:38 -0500
01 Dec 2002 05:53:06 +0800	Sun,  1 Dec 2002 05:53:06 +0800
