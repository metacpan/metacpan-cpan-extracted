# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CGI-ParamComposite.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

BEGIN {
  use Test::More tests => 15;
  use strict;
  use_ok('CGI');
  use_ok('CGI::ParamComposite');
  use_ok('Data::Dumper');
  use_ok('Symbol');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(my $q = CGI->new());
ok($q->param(-name=>'food.vegetable',-value=>['tomato','spinach']));
ok($q->param(-name=>'food.meat',     -value=>['pork','beef','fish']));
ok($q->param(-name=>'food.meat.pork',-value=>'bacon'));

ok(my $composite = CGI::ParamComposite->new( cgi => $q));
ok($composite->param());
ok($composite = CGI::ParamComposite->new( populate => 0 , cgi => $q));
ok($composite->param());
ok($composite = CGI::ParamComposite->new( populate => 1 , cgi => $q));
ok($composite->param());

ok($composite->param()->{food}->{meat});

#warn Dumper($composite->param());
