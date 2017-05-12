# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use lib 't/lib';
use App::rlibperl::Tester;
use Test::More;

plan tests => scalar @structures;

foreach my $structure ( @structures ) {
  my $tree = named_tree( $structure );

  my $script = 'test-rbin-script';

  make_file([$tree->{lib}, 'R_L_P_Tester.pm'], <<MOD);
package # no_index
  R_L_P_Tester;
our \$VERSION = 1.234;
MOD

  make_script([$tree->{bin}, $script], <<SCRIPT);
#!$^X
use strict;
use warnings;
use R_L_P_Tester;
local \$, = "\\t";
print "testing rbinperl", \$R_L_P_Tester::VERSION;
SCRIPT

  my $out = qx/$tree->{rbinperl} $script/;
  is(
    $out,
    "testing rbinperl\t1.234",
    "script used lib and returned expected output for '$structure'"
  );
}
