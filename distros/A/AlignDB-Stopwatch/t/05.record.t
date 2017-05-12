use strict;
use warnings;
use Test::More;

use AlignDB::Stopwatch;

my $stopwatch = AlignDB::Stopwatch->new->record;

is( $stopwatch->operation, '05.record.t' );
like( $stopwatch->cmd_line, qr{05\.record\.t} );

$stopwatch->record_conf( { is => 1, } );
like( $stopwatch->init_config, qr{\-{3}\s+is} );

done_testing();
