# $Id$
# Quick demo of inserting and retrieving unicode strings
# NOTE: your DBD::ODBC really needs to be built with unicode
# and this script will warn if not. You can comment the die out and it
# will work with some drivers without being built for unicode but you'll
# get slightly different output:
#
# with unicode:
# $VAR1 = [
#          [
#            "\x{20ac}" # note, is a unicode Perl string
#          ]
#        ];
# is utf8 1
#
# without unicode:
#
# $VAR1 = [
#          [
#            '€'   # note, not a unicode Perl string
#          ]
#        ];
# is utf8
#

use DBI;
use strict;
use Data::Dumper;
use utf8;

my $h = DBI->connect();
warn "Warning DBD::ODBC not built for unicode - you probably don't want to do this" if !$h->{'odbc_has_unicode'};

eval {
    $h->do(q/drop table mje/);
};

$h->do(q/create table mje (a nvarchar(20))/);

$h->do(q/insert into mje values(?)/, undef, "\x{20ac}");

my $s = $h->prepare(q/select * from mje/);
$s->execute;
my $f = $s->fetchall_arrayref;
print Dumper($f), "\n";

print "is utf8 ", utf8::is_utf8($f->[0][0]), "\n";
