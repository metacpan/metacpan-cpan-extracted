#!perl
use strict;
use warnings;
use Test::More;
use Test::NoWarnings;

use Data::Reach as => 'walk_down';


plan tests => 7;

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
is walk_down($data, qw/qux/),               'qux',         '1 step scalar';
is walk_down($data, qw/foo 3/),             1234,          'multistep short';




# exceptions
sub dies_ok (&$;$) {
  my ($coderef, $regex, $message) = @_;
  eval {$coderef->()};
  my $err = $@;

  like $err, $regex, $message;
}

# lexically-scoped "use Data::Reach" should not mess up with imported names
bless $data, 'RealClass'; # defined below
{ use Data::Reach reach_method => 'dup'; # no explicit import
  is walk_down($data, qw/foo/), "foofoo",              'call_method arrayref';
  dies_ok sub {walk_down($data, qw/foo 3/)},
          qr/within a SCALAR/,                         'call_method dup (2-steps)';

  dies_ok sub {reach($data, qw/foo 3/)},
          qr/Undefined subroutine/,                    'did not import "reach"';
}
{ use Data::Reach reach_method => 'dup', as => 'walk_down'; # same import
  is walk_down($data, qw/foo/), "foofoo",              'call_method arrayref';
}


package RealClass;
use strict;
use warnings;
sub dup {
  my ($self, $key) = @_;
  return "$key$key";
}

