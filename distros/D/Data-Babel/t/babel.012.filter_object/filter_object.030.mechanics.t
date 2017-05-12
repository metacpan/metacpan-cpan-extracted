########################################
# 030.mechanics -- test various Filter options
########################################
use t::lib;
use t::utilBabel;
use filter_object;
use Test::More;
use Data::Babel::Filter;
use strict;

init();
my $id='hello world';
my $qid=$dbh->quote($id);

## filter_idtype undefined
my $filter=new Data::Babel::Filter(babel=>$babel,conditions=>\":type_0 LIKE $qid");
cmp_sql($filter->sql,"type_0 LIKE $qid",'filter_idtype undefined - SQL with embedded idtype');
eval {
  my $filter=new Data::Babel::Filter(babel=>$babel,conditions=>$id);
};
ok($@,'filter_idtype undefined - ');
eval {
  my $filter=new Data::Babel::Filter(babel=>$babel,conditions=>\"LIKE $qid");
};
ok($@,'filter_idtype undefined - SQL without embedded idtype');
eval {
  my $filter=new Data::Babel::Filter(babel=>$babel,conditions=>\": LIKE $qid");
};
ok($@,'filter_idtype undefined - SQL with default embedded idtype');

## allow_sql=>0
my $filter=new Data::Babel::Filter
  (babel=>$babel,filter_idtype=>'type_0',conditions=>$id,allow_sql=>0);
cmp_sql($filter->sql,"type_0 = $qid",'allow_sql=>0 - id');
eval {
  my $filter=new Data::Babel::Filter
    (babel=>$babel,filter_idtype=>'type_0',conditions=>\"LIKE $qid",allow_sql=>0);
};
ok($@,'allow_sql=>0 - SQL');

## embedded_idtype_marker=>'?'
my $filter=new Data::Babel::Filter
  (babel=>$babel,filter_idtype=>'type_0',conditions=>\"? = $qid",embedded_idtype_marker=>'?');
cmp_sql($filter->sql,"type_0 = $qid",'embedded_idtype_marker=>? - default idtype');
my $filter=new Data::Babel::Filter
  (babel=>$babel,filter_idtype=>'type_0',conditions=>\"?type_1 = $qid",
   embedded_idtype_marker=>'?');
cmp_sql($filter->sql,"type_1 = $qid",'embedded_idtype_marker=>? - other idtype');
my $filter=new Data::Babel::Filter
  (babel=>$babel,filter_idtype=>'type_0',conditions=>\"? LIKE $qid AND ?type_1 = $qid",
   embedded_idtype_marker=>'?');
cmp_sql($filter->sql,"type_0 LIKE $qid AND type_1 = $qid",'embedded_idtype_marker=>? - default and other idtype');

## treat_string_as=>'sql'
my $filter=new Data::Babel::Filter(babel=>$babel,conditions=>":type_0 LIKE $qid",
				   treat_string_as=>'sql');
cmp_sql($filter->sql,"type_0 LIKE $qid",'treat_string_as=>sql - SQL');

## treat_stringref_as=>'id'
my $filter=new Data::Babel::Filter
  (babel=>$babel,filter_idtype=>'type_0',conditions=>\$id,treat_stringref_as=>'id');
cmp_sql($filter->sql,"type_0 = $qid",'treat_stringref_as=>id - id');

## prepend_idtype=>1
my $filter=new Data::Babel::Filter
  (babel=>$babel,filter_idtype=>'type_0',conditions=>\"LIKE $qid",prepend_idtype=>1);
cmp_sql($filter->sql,"type_0 LIKE $qid",'prepend_idtype=>1 - same as auto');
# this case generates illegal SQL - not sure why useful, but...
my $filter=new Data::Babel::Filter
  (babel=>$babel,filter_idtype=>'type_0',conditions=>\": LIKE $qid",prepend_idtype=>1);
cmp_sql($filter->sql,"type_0 type_0 LIKE $qid",'prepend_idtype=>1 - not same as auto');

## prepend_idtype=>0
my $filter=new Data::Babel::Filter
  (babel=>$babel,filter_idtype=>'type_0',conditions=>\"FALSE",prepend_idtype=>0);
cmp_sql($filter->sql,"FALSE",'prepend_idtype=>0');

done_testing();
