=head1 NAME

DBIx::TryAgain - If at first you don't succeed, try DBIx::TryAgain.

=head1 SYNOPSIS

 my $dbh = DBIx::TryAgain->connect(...) or die $DBI::errstr;

OR

 my $dbh = DBI->connect(... dbi params.. { RootClass => "DBIx::TryAgain" } ) or die $DBI::errstr;

 $dbh->try_again_algorithm('fibonacci');
 $dbh->try_again_max_retries(5);
 $dbh->try_again_on_messages([ qr/database is locked/i ]);
 $dbh->try_again_on_prepare(1);

=head1 DESCRIPTION

This is a subclass of DBI which simply tries to execute a query
again whenever the error string matches a given set of patterns.

By default the only pattern is qr[database is locked], which is
what is returned by SQLite when the database is locked.

There is a delay between retries.  Setting try_again_algorithm
to 'constant', 'linear', 'fibonacci', or 'exponential' causes
the corresponding algorithm to be used.  The first five
values for these algorithsm are :

    constant    : 1,1,1,1,1
    linear      : 1,2,3,4,5
    fibonacci   : 1,1,2,3,5
    exponential : 1,2,4,8,16

Modify the PrintError attribute and DBI_TRACE environment (as with
DBI) to change the level of verbosity of this module.

In addition to retrying an execute(), DBIx::TryAgain and also
retry a prepare statement, by calling $dbh->try_again_on_prepare(1);

=head1 AUTHOR

Brian Duggan, C<< <bduggan at matatu.org> >>

=head1 SEE ALSO

L<DBI>

=head1 TODO

Support error codes as well as messages.

=cut

package DBIx::TryAgain;

use strict;
use warnings;

our $VERSION = '0.05';

use DBI ( );
use DBIx::TryAgain::st;
use DBIx::TryAgain::db;

our @ISA = 'DBI';

