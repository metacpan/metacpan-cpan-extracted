use strict;
use warnings;

use Test::More tests => 3;
use Array::Splice qw ( splice_aliases );

my @args;
sub TIEARRAY { bless {} }
sub SPLICE_ALIASES { @args = @_; 7,8,9 } 
tie my @tied, 'main';

my @return = splice_aliases(@tied,5,10,1,2,3);

is(shift(@args), tied(@tied), 'Object passed to SPLICE_ALIASES');
is_deeply(\@args, [5,10,1,2,3], 'Arguments passed to SPLICE_ALIASES');
is_deeply(\@return, [7,8,9], 'Value returned from SPLICE_ALIASES');
