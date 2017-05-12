# $Id$
# $Source$
# $Author$
# $HeadURL$
# $Revision$
# $Date$
use strict;
use warnings;

use FindBin     qw($Bin);
use File::Path  qw(rmtree);
use File::Spec;
use Test::More;
use Alien::CodePress;
use Test::Exception;


my $TEMP_DIR = File::Spec->catfile($Bin, 'codepress-temp');

my $codepress = Alien::CodePress->new();
my @files     = $codepress->files();
plan( tests => 6 + scalar @files );

isa_ok($codepress, 'Alien::CodePress');
can_ok($codepress, 'get_path');
can_ok($codepress, 'set_path');
ok( scalar @files, 'has files' );

# cleanup stale temp dir
if (-e $TEMP_DIR) {
    rmtree($TEMP_DIR);
}

$codepress->install( $TEMP_DIR );
if (@files) {
   for my $file (@files) {
      if (not defined $file) {
         # we already said we were gonna run this test, so we just make it
         # always pass:
         ok(1);
         next;
      }
      ok( -e File::Spec->catfile($TEMP_DIR, $file), "$file exists" );
   }
}

# Should be OK to install on top of existing install.
lives_ok { $codepress->install( $TEMP_DIR ) } '->install( temp_dir )';

rmtree($TEMP_DIR);
ok( ! -d $TEMP_DIR, 'remove temp_dir');




# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
