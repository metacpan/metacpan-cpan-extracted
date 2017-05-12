package InitShareDBI;

use strict;
use warnings;
use DBI;

#LSF: This has to be loaded when loading this module.
unless ($InitShareDBI::dbh) {
    $InitShareDBI::dbh =
      DBI->connect( 'dbi:mysql:database=test;host=127.0.0.1;port=3306',
        'test', 'test', { PrintError => 1 } );
    #LSF: This will prevent it to be destroy.
    #$InitShareDBI::dbh->{InactiveDestroy} = 1;
}

{
    no warnings 'redefine';
    *DBI::db::DESTROY = sub {

        # NO OP.
    };
}

sub dbh {
    return $InitShareDBI::dbh;
}

1;
