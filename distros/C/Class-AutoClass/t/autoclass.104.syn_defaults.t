use strict;
use lib qw(t);
use Test::More;

# NG 05-12-08:  regression test for incorrect handling of defaults for synonyms.
#               consider syn=>'real'. there are 6 cases
#               args nothing, defaults syn
#               args syn, defaults syn
#               args real, defaults syn
#               args nothing, defaults real
#               args syn, defaults real
#               args real, defaults real

use autoclass_104::Parent_default_syn;
use autoclass_104::Parent_default_real;
use autoclass_104::Child_default_syn;
use autoclass_104::Child_default_real;

my($parent,$child);

note('Tests for handling of defaults with  synonyms. Parent only');
my $case;
$case='args nothing, defaults syn';
$parent=new autoclass_104::Parent_default_syn;
is($parent->syn,'default',"parent: $case");
$case='args syn, defaults syn';
$parent=new autoclass_104::Parent_default_syn(-syn=>'arg');
is($parent->syn,'arg',"parent: $case");
$case='args real, defaults syn';
$parent=new autoclass_104::Parent_default_syn(-real=>'arg');
is($parent->syn,'arg',"parent: $case");

$case='args nothing, defaults real';
$parent=new autoclass_104::Parent_default_real;
is($parent->syn,'default',"parent: $case");
$case='args syn, defaults real';
$parent=new autoclass_104::Parent_default_real(-syn=>'arg');
is($parent->syn,'arg',"parent: $case");
$case='args real, defaults real';
$parent=new autoclass_104::Parent_default_real(-real=>'arg');
is($parent->syn,'arg',"parent: $case");


note('Tests for handling of defaults with  synonyms. Parent and Child');
$case='args nothing, defaults syn';
$parent=new Parent;
$child=new autoclass_104::Child_default_syn;
ok(!$parent->syn,"parent: $case");
is($child->syn,'default',"child: $case");
$case='args syn, defaults syn';
$parent=new Parent(-syn=>'arg');
$child=new autoclass_104::Child_default_syn(-syn=>'arg');
is($parent->syn,'arg',"parent: $case");
is($child->syn,'arg',"child: $case");
$case='args real, defaults syn';
$parent=new Parent(-real=>'arg');
$child=new autoclass_104::Child_default_syn(-real=>'arg');
is($parent->syn,'arg',"parent: $case");
is($child->syn,'arg',"child: $case");

$case='args nothing, defaults real';
$parent=new Parent;
$child=new autoclass_104::Child_default_real;
ok(!$parent->syn,"parent: $case");
is($child->syn,'default',"child: $case");
$case='args syn, defaults real';
$parent=new Parent(-syn=>'arg');
$child=new autoclass_104::Child_default_real(-syn=>'arg');
is($parent->syn,'arg',"parent: $case");
is($child->syn,'arg',"child: $case");
$case='args real, defaults real';
$parent=new Parent(-real=>'arg');
$child=new autoclass_104::Child_default_real(-real=>'arg');
is($parent->syn,'arg',"parent: $case");
is($child->syn,'arg',"child: $case");

done_testing();
