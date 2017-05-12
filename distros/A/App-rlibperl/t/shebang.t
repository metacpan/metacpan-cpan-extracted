# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use lib 't/lib';
use App::rlibperl::Tester;
use Test::More;

# don't even bother with these:
plan skip_all => "Testing shebangs not supported on $^O"
  if $^O =~ /
      MSWin32
  /x;

my $exec_if_shell =
  # avoid -S for portability; we're using full paths, anyway
  sprintf(q<eval 'exec %s $0 ${1+"$@"}'%s>, $PERL, "\n  if 0;");

# try a quick interpreter shebang to see if it appears to be supported
{
  my $dir = tempdir( CLEANUP => 1 );
  my $parent = make_script([$dir, 'parent.pl'], <<SCRIPT);
#!$PERL
$exec_if_shell
print "parent";
do \$ARGV[0] if \@ARGV;
SCRIPT

  my $child  = make_script([$dir, 'child.pl' ], <<SCRIPT);
#!$parent
$exec_if_shell
print "child";
SCRIPT

  plan skip_all => "Nested shebangs not supported on $^O"
    unless qx/$child/ eq "parentchild";
}

plan tests => scalar @structures;

foreach my $structure ( @structures ) {
  my $tree = named_tree( $structure );

  make_file([$tree->{lib}, 'Silly_Interp.pm'], <<MOD);
package # no_index
  Silly_Interp;
sub parse {
  local \$_ = shift;
  return "bar." if /foo/;
  return "nertz." if /narf/;
}
1;
MOD

  my $interp = 'sillyinterp.pl';
  make_script([$tree->{bin}, $interp], <<SCRIPT);
#!$PERL
$exec_if_shell
use strict;
use warnings;
use Silly_Interp;
while(<>){
  print Silly_Interp::parse(\$_);
}
SCRIPT

  # put script somewhere separate
  my $scriptdir = tempdir( CLEANUP => 1 );
  my $script = make_script([$scriptdir, 'silly.pl'], <<SCRIPT);
#!$tree->{rbinperl} $interp
# OSes that use this exec will require repeating the shebang files:
eval 'exec $PERL $tree->{rbinperl} $interp \$0 \${1+"\$@"}'
  if 0;
foo()
narf.
SCRIPT

  is(
    qx/$script/,
    'bar.nertz.',
    "rbinperl used as shebang to invoke custom interpreter for '$structure'"
  );
}
