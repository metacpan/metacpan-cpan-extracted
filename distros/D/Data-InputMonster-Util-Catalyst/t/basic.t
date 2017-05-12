use strict;
use warnings;

use Test::More tests => 1;
use Test::Deep;
use Data::InputMonster;
use Data::InputMonster::Util::Catalyst '-all';

my $monster = Data::InputMonster->new({
  fields => {
    abc   => { sources => [ query_param        ] }, # get default name
    abc_2 => { sources => [ query_param('abc') ] }, # explicit name
    abc_3 => { sources => [ form_param('abc')  ] }, # from merged stuff
    ABC   => { sources => [ body_param('abc')  ] }, # no such body field

    ses_1 => { sources => [ session_entry('num')   ] }, # simple session
    ses_2 => { sources => [ session_entry(['num']) ] }, # simple session
    ses_3 => { sources => [ session_entry(sub{$_[0]->{num}}) ] }, # code
  }
});

my $output = $monster->consume('FakeCatalyst');

cmp_deeply(
  $output,
  {
    abc   => 1,
    abc_2 => 1,
    abc_3 => 1,
    ABC   => undef,

    ses_1 => 8675309,
    ses_2 => 8675309,
    ses_3 => 8675309,
  },
  'we got all the info out of our fake $c',
);

BEGIN {
  package FakeCatalyst;
  sub req { 'FakeCatalystReq' }

  my $session = {
    num => 8675309,
    foo => {
      x => [ 10, 20, 30 ],
      y => [ 11, 22, 33 ],
    },
  };

  sub session { $session }

  package FakeCatalystReq;
  my %query_param = (abc => 1, def => 2);
  my %body_param  = (uvw => 3, xyz => 4);
  sub query_params { \%query_param }
  sub body_params  { \%body_param  }
  sub params       { return { %query_param, %body_param } }
}
