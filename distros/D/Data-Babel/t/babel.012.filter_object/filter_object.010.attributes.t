########################################
# 010.attributes -- test attributes
# don't worry about use of filters in 'translate' - tested separately
########################################
use t::lib;
use t::utilBabel;
use filter_object;
use Test::More;
use Data::Babel;
use Data::Babel::Config;
use Data::Babel::Filter;
use strict;

init();

# create Filter with no arguments. $filter declared in filter_object
$filter=new Data::Babel::Filter;
isa_ok($filter,'Data::Babel::Filter','new with no arguments');

# get attributes
is($filter->babel,undef,'get attribute: babel');
is($filter->sql,undef,'get attribute: sql');
is($filter->filter_idtype,undef,'get attribute: filter_idtype');
is($filter->conditions,undef,'get attribute: conditions');
is_deeply($filter->filter_idtypes,[],'get attribute: filter_idtypes');
# these guys have defaults
is($filter->allow_sql,1,'get attribute: allow_sql');
is($filter->embedded_idtype_marker,':','get attribute: embedded_idtype_marker');
is($filter->treat_string_as,'id','get attribute: treat_string_as');
is($filter->treat_stringref_as,'sql','get attribute: treat_stringref_as');
is($filter->prepend_idtype,'auto','get attribute: prepend_idtype');

# set & re-get attributes
test_setget('babel',$babel);
test_setget('sql',qq(xxx='yyy'));
test_setget('filter_idtype','xxx');
test_setget('conditions','yyy');
test_setget('filter_idtypes',[qw(xxx yyy)]);
test_setget('allow_sql',0);
test_setget('embedded_idtype_marker','***');
test_setget('prepend_idtype',1);

# these guys have specific default amd legal values
test_setget_choices('treat_string_as',qw(id sql));
test_setget_choices('treat_stringref_as',qw(sql id));

done_testing();

