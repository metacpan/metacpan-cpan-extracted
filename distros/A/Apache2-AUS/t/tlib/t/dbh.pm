#!perl

package t::dbh;

use strict;
use warnings;
use Apache::TestMB;
use Exporter;
use base q(Exporter);
use DBIx::Transaction;

our @EXPORT = qw(test_db dbh);

return 1;

sub test_db {
    my $build = Apache::TestMB->current;
    return unless $build->notes('DBI_DSN');
    return map {
        defined $build->notes($_) ? $build->notes($_) : ''
    } qw(DBI_DSN DBI_USER DBI_PASS);
}

sub dbh {
    my(@db_opts) = test_db();
    if(@db_opts) {
        return DBIx::Transaction->connect(
            @db_opts,
            {
                PrintWarn => 0,
                AutoCommit => 1,
                RaiseError => 1,
                PrintError => 0
            }
        );
    } else {
        return;
    }
}
