#!perl
use strict;
use warnings;
use Test::More;
use Test::NoWarnings;

use Data::Reach;

plan tests => 29;

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
is reach($data, qw/qux/),               'qux',     '1 step scalar';
is reach($data, qw/foo 3/),             1234,      'multistep short';
is reach($data, qw/foo -1/),            1234,      'negative index';
is reach($data, qw/foo 2 bar buz/),     987,       'multistep long';
is reach($data, qw/foobar/),            undef,     'absent hash key';
is reach($data, qw/foo 5/),             undef,     'absent array key';
is reach($data, 'foo', undef, 1),       undef,     'undef in path';
is reach(undef, qw/qux/),               undef,     'undef root';
is_deeply reach($data), $data,                     'empty path';
my $tmp = reach($data, qw/foo 2/);
is reach($tmp, qw/bar buz/),            987,       'intermediate node';

# recursive data structure
$data->{foo}[2]{bar}{recurse} = $data;
my @recurse_path = qw/foo 2 bar recurse/ x 10;
is reach($data, (@recurse_path, 'qux')), 'qux',    'recursive data';

# exceptions
sub dies_ok (&$;$) {
  my ($coderef, $regex, $message) = @_;
  eval {$coderef->()};
  like $@, $regex, $message;
}
dies_ok sub {reach $data, qw/foo bar/}, 
        qr/cannot.*array/,                         'wrong array index';
dies_ok sub {reach $data, qw/foo 2 bar buz 321/},
        qr/within a SCALAR/,                       'multistep too long';
dies_ok sub {reach $data, qw/stringref 321/},
        qr/within a SCALARREF/,                    'stringref';
dies_ok sub {reach $data, qw/refref 321/},
        qr/within a REFREF/,                       'refref';


# option "peek_blessed"
bless $data, 'PhantomClass';
is reach($data, qw/foo 3/), 1234,                  'peek_blessed true';
{ no Data::Reach qw/peek_blessed/;

  dies_ok sub {reach($data, qw/foo 3/)},
          qr/within an object/,                    'peek_blessed false';
}
is reach($data, qw/foo 3/), 1234,                  'peek_blessed true again';



# option "call_method"
bless $data, 'RealClass'; # defined below
{ use Data::Reach call_method => [qw/dap dip dup/];
  is reach($data, qw/foo/), "foofoo",              'call_method arrayref';
  dies_ok sub {reach($data, qw/foo 3/)},
          qr/within a SCALAR/,                     'call_method dup (2-steps)';
}
is reach($data, qw/foo 3/), 1234,                  'call_method disabled';
{ use Data::Reach call_method => 'dup';
  is reach($data, qw/foo/), "foofoo",              'call_method scalar';
}


# option "use_overloads"
is reach($data, qw/0/), 1,                         'use_overloads true';
{ no Data::Reach qw/use_overloads/;
  is reach($data, qw/0/), undef,                   'use_overloads false';
}
is reach($data, qw/0/), 1,                         'use_overloads true again';


# objects that are not arrayrefs
$data = bless [qw/a b c/], 'PhantomClass';
is reach($data, qw/0/), 'a',                       'peek into array';

$data = bless sub {}, 'PhantomClass';
dies_ok sub {reach($data, qw/0/)},
        qr/within a CODEREF/,                      'peek into coderef';

$data = bless \my $foo, 'PhantomClass';
dies_ok sub {reach($data, qw/0/)},
        qr/within a SCALARREF/,                    'peek into scalarref';


package RealClass;
use strict;
use warnings;
use overload '@{}' => sub {
  my $foo = [1, 2, 3];
  return $foo;
};

sub dup {
  my ($self, $key) = @_;
  return "$key$key";
}

