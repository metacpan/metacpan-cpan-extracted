BEGIN
{ 
   use Test::More tests => 6;
   use_ok(CAM::Template);
}

use strict;
use Carp;
$SIG{__WARN__} = \&Carp::cluck;
$SIG{__DIE__} = \&Carp::confess;

no strict qw(refs); # needed for isDiff function, below

## FIRST create some before and after strings
my $templatestring = ( <<"EOF"

??!hardtest??
??!test??test??!test??
??!test??test??!test??
??!hardtest??

This is a test string. It sets constants::replace==replace::.  It has
constant ::replace:: variables.  It has ::dynamic_replace::
variables.  It supports a <!-- ::variety::--> of ;;replace-ment;;
syntaxes.
??conditional??
It has ::conditional:: blocks.??nested??  It supports ??!shallow??deeply??!shallow?? nested ??both??of both kinds ??both??conditionals too.??nested??
??conditional??
??!conditional??
It skips false ::conditional:: blocks.
??!conditional??
<cam_loop name="loop">
::n::. It supports loops</cam_loop>
EOF
               );

my $comparestring = (<<"EOF"


test
test


This is a test string. It sets constants.  It has
constant replace variables.  It has dynamic replace
variables.  It supports a variety of replacement
syntaxes.

It has conditional blocks.  It supports deeply nested conditionals too.



1. It supports loops
2. It supports loops
3. It supports loops
4. It supports loops
5. It supports loops
6. It supports loops
EOF
               );

# This script will be treated as a template.  This will break if
# Test::Harness is used.

local *FILE;
open(FILE, $0) or die "cannot read myself";
my $selftemplate = join('', <FILE>);
close(FILE);

my $selfcompare = $selftemplate;
$selfcompare =~ s/\Q$templatestring\E/$comparestring/;


## THEN run the tests

my $out;
my $t = CAM::Template->new($0);
$t->setParams(
              conditional => "conditional",
              dynamic_replace => "dynamic replace",
              "replace-ment" => "replacement",
              );
$t->addParams({variety => "variety", nested => 1});
$t->addLoop("loop", n => $_) for (1..3);
$t->addLoop("loop", [
                     {n => 4},
                     {n => 5},
                     {n => 6},
                     ]);

# Escape the ":"s just so this string does not look like a var to replace
is($t->{content}->{loops}->{loop}, "\n\:\:n\:\:. It supports loops",
   'loop check');

SKIP: {
   eval { require FileHandle };

   skip "FileHandle module is not installed", 1 if $@;

   my $OUTFH;
   $OUTFH = new FileHandle(">TempTestOut.$$") or die "cannot write a test output file";
   $t->print($OUTFH);
   $OUTFH->close();
   $OUTFH = new FileHandle("<TempTestOut.$$") or die "cannot read the test output file";
   $out = join('', <$OUTFH>);
   $OUTFH->close();
   unlink("TempTestOut.$$") or die "failed to delete the test output file";

   isDiff($out, $selfcompare, "replace file with print");
}

$t->setString($templatestring);
$out = $t->toString();
isDiff($out, $comparestring, "replace string with toString");

$t->setFilename($0);
$out = $t->toString();
isDiff($out, $selfcompare, "replace file with toString");

$t->setFileCache(0);
$t->setFilename($0);
$out = $t->toString();
isDiff($out, $selfcompare, "replace file with toString w/o filecache");

# Performance testing
my $niter = 500;
my $start;
my $stop;

print "## Tests of load and replace\n";

$start = getTime();
for (my $i=0; $i<$niter; $i++)
{
   my $t = CAM::Template->new();
   $t->setFileCache(1);
   $t->setFilename($0);
   $out = $t->toString();
}
$stop = getTime();
print "# Performance test: ".sprintf("%.2f",$stop-$start)." seconds for $niter iterations with filecache\n";

$t->setFileCache(0);
$start = getTime();
for (my $i=0; $i<$niter; $i++)
{
   my $t = CAM::Template->new();
   $t->setFileCache(0);
   $t->setFilename($0);
   $out = $t->toString();
}
$stop = getTime();
print "# Performance test: ".sprintf("%.2f",$stop-$start)." seconds for $niter iterations without filecache\n";

print "## Tests of just replace\n";
print "## 'hard' means a template with lots of syntax to search and replace\n";
print "## 'easy' means a template of just content, nothing to replace\n";

$t->setFilename($0);
$t->study();
$start = getTime();
for (my $i=0; $i<$niter; $i++)
{
   $out = $t->toString();
}
$stop = getTime();
print "# Performance test: ".sprintf("%.2f",$stop-$start)." seconds for $niter hard iterations with study\n";

$t->setFilename($0);
$start = getTime();
for (my $i=0; $i<$niter; $i++)
{
   $out = $t->toString();
}
$stop = getTime();
print "# Performance test: ".sprintf("%.2f",$stop-$start)." seconds for $niter hard iterations without study\n";

my $simple = " " x length($t->{content}->{string});
$t->setString($simple);
$t->study();
$start = getTime();
for (my $i=0; $i<$niter; $i++)
{
   $out = $t->toString();
}
$stop = getTime();
print "# Performance test: ".sprintf("%.2f",$stop-$start)." seconds for $niter easy iterations with study\n";

$t->setString($simple);
$start = getTime();
for (my $i=0; $i<$niter; $i++)
{
   $out = $t->toString();
}
$stop = getTime();
print "# Performance test: ".sprintf("%.2f",$stop-$start)." seconds for $niter easy iterations without study\n";

# TODO:
# test resetting the params hash
# test print method
# test setFileCache method better
# test alternate syntaxes of new()


sub isDiff
{
   # Works like is(), but does a diff on output instead of printing
   # the whole content.

   my $v1 = shift;
   my $v2 = shift;
   my $label = shift;

   # Have to escape the :: stuff so we don't mistaken look like
   # template parameters.  Plus, this looks more portable...  :-)
   my $pkg = "Text::Diff";
   
   if (!defined ${$pkg."::VERSION"})
   {
      eval "use $pkg;";
      if ($@ || (!defined ${$pkg."::VERSION"}))
      {
         ${$pkg."::VERSION"} = 0;
      }
      else
      {
         ${$pkg."::test_options"} = {
                                     STYLE => "Unified",
                                     FILENAME_A => "Got",
                                     FILENAME_B => "Wanted",
                                     };
      }
   }
   if (${$pkg."::VERSION"})
   {
      if ($v1 ne $v2)
      {
         my $diff = diff(\$v1, \$v2, ${$pkg."::test_options"});
         $diff =~ s/^/# /gm;
         print $diff;
      }
      ok($v1 eq $v2, $label);
   }
   else
   {
      is($v1, $v2, $label);
   }
}

sub getTime
{
   my($user,$system,$cuser,$csystem)=times;
   return $user+$system+$cuser+$csystem;
}
