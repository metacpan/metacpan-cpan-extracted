#!perl
use strict;
use warnings;
use Test::More;
use Test::NoWarnings;

use Data::Reach ();

plan tests => 4;

# test data
my $data = {
  foo => [ undef,
           'abc',
           {bar => {buz => 987}},
           1234,
          ],
  qux => 'qux',
  stringref => \"ref",
  refref => \\"ref",
};


# ordinary test cases
is Data::Reach::reach($data, qw/qux/),       'qux',     '1 step scalar';
is Data::Reach::reach($data, qw/foo 3/),     1234,      'multistep short';


# exceptions
sub dies_ok (&$;$) {
  my ($coderef, $regex, $message) = @_;
  eval {$coderef->()};
  like $@, $regex, $message;
}


dies_ok sub {reach($data, qw/foo 3/)},
        qr/Undefined subroutine/,                       'did not import "reach"';


