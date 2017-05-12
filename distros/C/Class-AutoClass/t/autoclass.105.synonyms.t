use strict;
use lib qw(t);
# use lib map {glob($_)} qw(../lib ~/lib/perl5 ~/lib/perl5/site_perl/5.8.5);
use Parent;
use Child;
use Test::More;

# this is a regression test covering a bug (SF# 1222961) where synonyms are not created consistent
# with the documentation

# gender is a synonym for sex
my $parent=new Parent;
$parent->sex('male');
is($parent->gender, 'male', 'var set using "gender", read using "sex"');
$parent->gender('female');
is($parent->sex, 'female', 'var set using "sex", read using "gender"');
$parent->sex('???');
is($parent->whatisya, '???', 'var set using "sex", read using "whatisya" synonym'); # testing second synonym

# NG 05-12-10: added tests for synonyms defined in Child
my $child=new Child(stork=>'brought you');
is($child->sex, 'brought you', 'var set using "stork" (Child synonym), read using "sex"');
undef $child;
$child=new Child;
$child->stork('brought you');
is($child->sex, 'brought you', 'var set using "stork" (Child synonym), read using "sex"');
undef $child;
$child=new Child(sex=>'brought you');
is($child->stork, 'brought you', 'var set using "sex" (Parent), read using "stork"');
undef $child;
$child=new Child(whatisya=>'brought you');
is($child->stork, 'brought you', 'var set using "whatisya" (Parent synonym), read using "stork"');

done_testing();
