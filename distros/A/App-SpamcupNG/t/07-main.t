use warnings;
use strict;
use Test::More;    # tests => 2;

use App::SpamcupNG qw(main_loop config_logger);

use lib './t';
use UserAgent;

my $ua   = UserAgent->new();
my %opts = (
    delay      => 1,
    ident      => 'foobar',
    pass       => 'foobar',
    stupid     => 1,
    check_only => 0
);
config_logger( 'INFO', 'foobar.log' );

is( main_loop( $ua, \%opts ), 1, 'main_loop finished successfully' );
done_testing;
