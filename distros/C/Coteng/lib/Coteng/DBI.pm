package Coteng::DBI;
use strict;
use warnings;

use parent qw(DBIx::Sunny);


package Coteng::DBI::db;

use parent -norequire => 'DBIx::Sunny::db';

sub __set_comment {
    my $self = shift;
    my $query = shift;

    my $trace;
    my $i = 0;
    while ( my @caller = caller($i) ) {
        my $file = $caller[1];
        $file =~ s!\*/!*\//!g;
        $trace = "/* $file line $caller[2] */";
        last if $caller[0] ne ref($self) && $caller[0] !~ /^(:?DBIx?|DBD|Coteng)\b/;
        $i++;
    }
    $query =~ s! ! $trace !;
    $query;
}

package Coteng::DBI::st;
use parent -norequire => 'DBIx::Sunny::st';

1;
