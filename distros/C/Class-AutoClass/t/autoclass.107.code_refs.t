package DefaultRefs;

# this is a regression test covering a bug when using a CODE reference as a DEFAULT
# it's a tivial problem: we mindlessly use dclone to copy all DEFAULTS that are 
#   references, but dclone chokes on CODE refs. everything else should be fine.

use strict;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS);
our $glob_target="target for testing glob default";
@AUTO_ATTRIBUTES=qw(array_ref hash_ref scalar_ref code_ref glob_ref);
%DEFAULTS=(array_ref=>['array default',1,2,3],
	   hash_ref=>{'hash default'=>'me',abc=>123},
	   scalar_ref=>\"hello world as scalar default",
	  code_ref=>sub {return "hello world from code default"},
	  glob_ref=>\*glob_target,
	  );
Class::AutoClass::declare;

package main;
use strict;
use Test::More;
use Test::Deep;

# make object and make sure defaults set
my $obj0=new DefaultRefs;
my $label='obj0 initial state';
cmp_deeply($obj0->array_ref,['array default',1,2,3],"$label: array ref");
cmp_deeply($obj0->hash_ref,{'hash default'=>'me',abc=>123},"$label: hash ref");
is(${$obj0->scalar_ref},"hello world as scalar default","$label: scalar ref");
my $sub=$obj0->code_ref;
ok(('CODE' eq ref $sub) && (&$sub() eq "hello world from code default"),"$label: code ref");
my $glob=$obj0->glob_ref;
ok(('GLOB' eq ref $glob) && ($$$glob eq "target for testing glob default"),"$label: code ref");

# update obj0, then make another object to prove that defaults unchanged
splice(@{$obj0->array_ref},0,1,'after update');
$obj0->hash_ref->{'hash default'}='not me';
${$obj0->scalar_ref}="hello world after update to scalar ref";
# cannot update code or glob refs
my $label='obj0 after update';
cmp_deeply($obj0->array_ref,['after update',1,2,3],"$label: array ref");
cmp_deeply($obj0->hash_ref,{'hash default'=>'not me',abc=>123},"$label: hash ref");
is(${$obj0->scalar_ref},"hello world after update to scalar ref","$label: scalar ref");


my $obj1=new DefaultRefs;
my $label='obj1 after update';
cmp_deeply($obj1->array_ref,['array default',1,2,3],"$label: array ref");
cmp_deeply($obj1->hash_ref,{'hash default'=>'me',abc=>123},"$label: hash ref");
is(${$obj1->scalar_ref},"hello world as scalar default","$label: scalar ref");
my $sub=$obj1->code_ref;
ok(('CODE' eq ref $sub) && (&$sub() eq "hello world from code default"),"$label: code ref");
my $glob=$obj1->glob_ref;
ok(('GLOB' eq ref $glob) && ($$$glob eq "target for testing glob default"),"$label: code ref");

done_testing();
