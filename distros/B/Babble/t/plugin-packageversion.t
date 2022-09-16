use strictures 2;
use Test::More;
use Babble::Plugin::PackageVersion;
use Babble::Match;

my $pv = Babble::Plugin::PackageVersion->new;

my @cand = (
  # no version, no change
  [ 'package Foo::Bar { 42 }',
    'package Foo::Bar { 42 }', ],
  [ 'package Foo::Bar; 42',
    'package Foo::Bar; 42', ],

  # statement - v-string
  [ 'package Foo::Bar v1.2.3;
42',
    q{package Foo::Bar;
our $VERSION = 'v1.2.3';

42}, ],

  # statement - decimal
  [ 'package Foo::Bar 1.30;
42',
    q{package Foo::Bar;
our $VERSION = '1.30';

42}, ],

  # block - v-string
  [ 'package Foo::Bar v1.2.3 { 42 }',
    q{package Foo::Bar {
our $VERSION = 'v1.2.3';
42 }}, ],

  # block - decimal
  [ 'package Foo::Bar 1.30 { 42 }',
    q{package Foo::Bar {
our $VERSION = '1.30';
42 }}, ],

  # single statement (no ;)
  [ 'package Foo::Bar v1.2.3',
    q{package Foo::Bar;
our $VERSION = 'v1.2.3';
}, ],

  # single statement in block (with ;)
  [ '{package Foo::Bar 1.30;}',
    q{{package Foo::Bar;
our $VERSION = '1.30';
}}, ],
  [ '{package Foo::Bar 1.30; 42}',
    q{{package Foo::Bar;
our $VERSION = '1.30';
 42}}, ],

  # single statment in block (no ;)
  #
  # This fails because the PPR grammar considers the whole code a PerlStatement
  # and this matches the
  #
  #   Inlined (?&PerlPackageDeclaration)
  #
  # part of the grammar.
  #
  # It may be such a small edge case that it might not be worth supporting.
  ( [ '{package Foo::Bar 1.30}',
    q{{package Foo::Bar;
our $VERSION = '1.30';
}}, ] )x(0),# removes this specific test case
);

foreach my $cand (@cand) {
  my ($from, $to) = @$cand;
  my $top = Babble::Match->new(top_rule => 'Document', text => $from);
  $pv->transform_to_plain($top);
  is($top->text, $to, "${from}");
}

done_testing;
