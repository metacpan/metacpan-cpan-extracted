# $Id$
#
# Small example showing how you can insert unicode inline in the SQL
#
# expected output:
#Has unicode: 1
#$VAR1 = [
#          [
#            "\x{20ac}"
#          ]
#        ];
#$VAR1 = [
#          [
#            "\x{20ac}"
#          ],
#          [
#            "\x{20ac}"
#          ]
#        ];
#
use DBI;
use strict;
use warnings;
use Data::Dumper;

my $h = DBI->connect();
#$h->{odbc_default_bind_type} = 12;

warn "Warning DBD::ODBC not built for unicode - this will not work as expected" if !$h->{'odbc_has_unicode'};

eval {$h->do(q/drop table martin/);};

print "Has unicode: " . $h->{odbc_has_unicode} . "\n";

$h->do(q/create table martin (a nvarchar(100))/);

my $s = $h->prepare(q/insert into martin values(?)/);
$s->execute("\x{20ac}");

my $r = $h->selectall_arrayref(q/select * from martin/);
print Dumper($r);

my $sql = 'insert into martin values(' . $h->quote("\x{20ac}") . ')';
$h->do($sql);

$r = $h->selectall_arrayref(q/select * from martin/);
print Dumper($r);

#--with-iconv-char-enc=
#--with-iconv-ucode-enc=enc
