package t::Util;

use strict;
use warnings;
use DBI;
use File::Temp qw/tempfile/;

sub setup_mysqld {
    my $mysqld = Test::mysqld->new(my_cnf => {
        'skip-networking' => '',
    }) or die "Can't create mysqld:[$!]";
    my $dbh = DBI->connect($mysqld->dsn(dbname => 'mysql'), '', '',
                           {
                               AutoCommit => 1,
                               RaiseError => 1,
                           },
                       ) or die $DBI::errstr;
    ($mysqld, $dbh);
}

sub capture(&) {
    my ($code) = @_;

    open my $fh, '>', \my $content;
    $fh->autoflush(1);
    local $DBIx::AssertIndex::OUTPUT = $fh;
    $code->();
    close $fh;
    return $content;
}

1;
