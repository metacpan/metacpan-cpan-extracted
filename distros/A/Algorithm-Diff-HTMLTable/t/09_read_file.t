#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp;
use Algorithm::Diff::HTMLTable;

my $table = Algorithm::Diff::HTMLTable->new;

{
    is $table->_read_file, undef, 'No file at all';
    is $table->_read_file({}), undef, 'Hashref is not accepted';
    is_deeply [$table->_read_file(['Test']) ], ['Test'], 'Arrayref - handled as lines';
    is_deeply [$table->_read_file([]) ], [], 'Arrayref - handled as lines';
    is $table->_read_file( '/does/not/exist/algorithm_diff_htmltable.t' ), undef;
}

{
    my $fh = File::Temp->new;
    binmode $fh, ':encoding(utf-8)';
    print $fh "Hallo\nTest";
    my $name = $fh->filename;
    close $fh;

    is_deeply [ $table->_read_file( $name ) ], ["Hallo\n", "Test"];
}

done_testing();
