use warnings;
use strict;
use Test::More tests => 1;
use File::Spec;
use Test::TempDir::Tiny;

use App::SpamcupNG qw(main_loop config_logger);

use lib './t';
use UserAgent;

my $dir = tempdir();

my $ua   = UserAgent->new();
my %opts = (
    delay      => 1,
    ident      => 'foobar',
    pass       => 'foobar',
    stupid     => 1,
    check_only => 0,
    database   => {
        enabled => 1,
        path    => File::Spec->catfile( $dir, 'sample.db' )
    }
);
config_logger( 'INFO', 'foobar.log' );
is( main_loop( $ua, \%opts ), 1, 'main_loop finished successfully' );

# vim: filetype=perl

