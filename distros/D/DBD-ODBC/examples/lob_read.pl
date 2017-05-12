# $Id$
#
# Example of DBD::ODBC's lob_read
#
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);
#use DBIx::Log4perl;
use DBI qw(:sql_types);
use strict;
use warnings;

#my $h = DBI->connect("dbi:ODBC:baugi","sa","easysoft",
#                     {PrintError => 1, RaiseError => 1, PrintWarn => 1});
my $h = DBI->connect;
$h->{PrintError} = $h->{RaiseError} = $h->{PrintWarn} = 1;

my $s = $h->prepare(q{select 'frederickfrederick'});
$s->execute;
$s->bind_col(1, undef, {TreatAsLOB=>1});
$s->fetch;

getit($s, SQL_BINARY);

$s = $h->prepare(q{select 'frederickfrederick'});
$s->execute;
$s->bind_col(1, undef, {TreatAsLOB=>1});
$s->fetch;

# NOTE the difference between receiving something as binary and as a char
# ODBC's SQLGetData is defined as putting a terminating NUL chr at the
# end of strings so even though we ask for 8 we get 7 bytes
getit($s, SQL_CHAR);

sub getit{
    my ($s, $type) = @_;
    my $len;
    while($len = $s->odbc_lob_read(1, \my $x, 8, {TYPE => $type})) {
        print "len=$len, x=$x, ", length($x), "\n";
    }
    print "len at end = $len\n";
    my $x;
    $len = $s->odbc_lob_read(1, \$x, 8);
    print  "len after read $len\n";
}
