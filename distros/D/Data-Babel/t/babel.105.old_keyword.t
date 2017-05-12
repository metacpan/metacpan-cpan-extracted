########################################
# regression test for 'old' method, keyword form, autodb not specified
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use File::Spec;
use Class::AutoDB;
use Data::Babel;
use strict;

my $autodb=new Class::AutoDB(database=>'test',create=>1);
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
my $name='test';
my $babel=new Data::Babel(name=>$name,autodb=>$autodb);
is(Data::Babel->autodb,$autodb,'sanity test - new sets autodb class attribute');
my $babel_sav=$babel;
$babel=old Data::Babel($name);
is($babel,$babel_sav,'old positional form');
$babel=old Data::Babel(name=>$name);
is($babel,$babel_sav,'old keyword form');

done_testing();
