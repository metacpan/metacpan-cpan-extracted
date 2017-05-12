package TestInstrument::dbi;

use strict;
use warnings FATAL => 'all';

use Apache::Test qw(-withtestmore);

use Apache2::Const -compile => 'OK';
use DBI;

sub handler : method {
    my ($class, $r) = @_;
    
    plan $r, tests => 1;
    
    my $dbh = DBI->connect("dbi:SQLite:dbname=/tmp/foo.sqlite");
    $dbh->do("DROP table foo");
    $dbh->do("CREATE table foo (id int, val text)");
    $dbh->do("INSERT INTO foo (id, val) VALUES (1,'test')");
    
    ok(1);
    
    return Apache2::Const::OK;
}

1;
__END__
PerlInitHandler Apache2::Instrument::DBI
PerlOptions +GlobalRequest
