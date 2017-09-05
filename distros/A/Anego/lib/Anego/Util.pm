package Anego::Util;
use strict;
use warnings;
use utf8;
use parent qw/ Exporter /;

use Anego::Logger;
use Anego::Config;

our @EXPORT = qw/ do_sql /;

sub do_sql {
    my ($sql) = @_;
    my $config = Anego::Config->load;

    my @statements = map { "$_;" } grep { /\S+/ } split /;/, $sql;
    for my $statement (@statements) {
        $config->dbh->do($statement) or errorf($config->dbh->errstr)
    }
}

1;
