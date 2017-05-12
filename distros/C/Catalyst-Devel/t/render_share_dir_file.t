use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Catalyst::Helper;
use Test::More;

my $helper = bless {}, 'Catalyst::Helper';

use File::Temp qw/tempfile/;

my ($fh, $fn) = tempfile;
close $fh;

ok( $helper->render_sharedir_file('script/myapp_cgi.pl.tt', $fn, { appprefix  => 'fnargh' }), "sharedir file rendered" ); 
ok -r $fn;
ok -s $fn;
unlink $fn;

done_testing;
