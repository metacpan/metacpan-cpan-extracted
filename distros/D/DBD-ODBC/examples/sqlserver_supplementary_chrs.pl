# $Id$
#
# Quick example demonstrating you can insert and retrieve
# supplementary characters from MS SQL Server 2012 - it won't work before this version
#
# See http://msdn.microsoft.com/en-us/library/ms143726.aspx
#     http://msdn.microsoft.com/en-us/library/bb330962(v=sql.90).aspx
#
use strict;
use warnings;
use DBI;
use Unicode::UCD 'charinfo';
use Data::Dumper;
#use charnames ':full';
use Test::More;
use Test::More::UTF8;

binmode(STDOUT, ":encoding(UTF-8)");
binmode(STDERR, ":encoding(UTF-8)");

# unicode chr above FFFF meaning it needs a surrogate pair
my $char = "\x{2317F}";
my $charinfo   = charinfo(0x2317F);
print Dumper($charinfo);
#print "0x2317F is : ", charnames::viacode(0x2317F), "\n";

my $h = DBI->connect() or BAIL_OUT("Failed to connect");

BAIL_OUT("Not a unicode build of DBD::ODBC") if !$h->{odbc_has_unicode};
$h->{RaiseError} = 1;
$h->{ChopBlanks} = 1;
$h->{RaiseError} = 1;

eval {
    $h->do('drop table mje');
};

# create table ensuring collation specifieds _SC
# for supplementary characters.
$h->do(q/create table mje (a nchar(20) collate Latin1_General_100_CI_AI_SC)/);

my $s = $h->prepare(q/insert into mje values(?)/);
my $inserted = $s->execute("\x{2317F}");
is($inserted, 1, "inserted one row");

my $r = $h->selectall_arrayref(q/select a, len(a), unicode(a), datalength(a) from mje/);
print Dumper($r);
print "Ordinals of received/sent: ", ord($r->[0][0]), ", ", ord($char), "\n";
print DBI::data_diff($r->[0][0], $char);
is($r->[0][0], $char);
is($r->[0][1], 1);
is($r->[0][2], 143743);

done_testing;
