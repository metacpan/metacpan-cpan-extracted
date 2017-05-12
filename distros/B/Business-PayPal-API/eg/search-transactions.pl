use strict;
use warnings;
use feature qw( say );

use Data::Printer;

use lib 'eg/lib';

use Example::TransactionSearcher;

my $searcher = Example::TransactionSearcher->new_with_options();
my $txns     = $searcher->search;
unless ( @{$txns} ) {
    say 'no results';
    exit;
}

foreach my $txn ( @{$txns} ) {

    # remove undef values
    for my $field ( keys %{$txn} ) {
        delete $txn->{$field} unless $txn->{$field};
    }
    p $txn;
}

say scalar @{$txns} . ' results found';
