#!perl -w

use strict;
use Test;
plan tests => 10;

use Data::Dump::Perl6 qw(dump_perl6);

my $DOTS = "." x 20;

ok(dump_perl6({}), "{}");
ok(dump_perl6({ a => 1}), "{ a => 1 }");
ok(dump_perl6({ 1 => 1}), "{ 1 => 1 }");
ok(dump_perl6({strict => 1, abc => 2, -f => 3 }),
    q[{ "-f" => 3, "abc" => 2, "strict" => 1 }]);
ok(dump_perl6({supercalifragilisticexpialidocious => 1, a => 2}),
    "{ a => 2, supercalifragilisticexpialidocious => 1 }");
ok(dump_perl6({supercalifragilisticexpialidocious => 1, a => 2, b => $DOTS})."\n", <<EOT);
{
  a => 2,
  b => "$DOTS",
  supercalifragilisticexpialidocious => 1,
}
EOT
ok(dump_perl6({aa => 1, shift => 3, B => 2}), "{ aa => 1, B => 2, shift => 3 }");
ok(dump_perl6({a => 1, bar => $DOTS, baz => $DOTS, foo => 2 })."\n", <<EOT);
{
  a   => 1,
  bar => "$DOTS",
  baz => "$DOTS",
  foo => 2,
}
EOT
ok(dump_perl6({a => 1, "b-z" => 2}), qq({ "a" => 1, "b-z" => 2 }));

my $h = do {
  my $a = {
    main => [
      {
        call => [
                  {
                    arg => [
                      {
                        main => [
                          bless(do{\(my $o = "hello")}, "Sidef::Types::String::String"),
                        ],
                      },
                    ],
                    method => "=",
                  },
                ],
        self => bless({
                  vars => [
                    bless({
                      class  => "main",
                      in_use => 1,
                      name   => "x",
                      type   => "var",
                      value  => bless(do{\(my $o = undef)}, "Sidef::Types::Nil::Nil"),
                    }, "Sidef::Variable::Variable"),
                  ],
                }, "Sidef::Variable::Init"),
      },
      { call => [{ method => "say" }], self => 'fix' },
    ],
  };
  $a->{main}[1]{self} = $a->{main}[0]{self}{vars}[0];
  $a;
};

ok(dump_perl6($h)."\n", <<'EOT');
do {
  my $a = {
    main => [
      {
        call => [
                  {
                    arg => [
                      {
                        main => [Sidef::Types::String::String.bless(content => "hello")],
                      },
                    ],
                    method => "=",
                  },
                ],
        self => Sidef::Variable::Init.bless(content => {
                  vars => [
                    Sidef::Variable::Variable.bless(content => {
                      class  => "main",
                      in_use => 1,
                      name   => "x",
                      type   => "var",
                      value  => Sidef::Types::Nil::Nil.bless(content => Nil),
                    }),
                  ],
                }),
      },
      { call => [{ method => "say" }], self => Any },
    ],
  };
  $a<main>[1]<self> = $a<main>[0]<self>.content<vars>[0];
  $a;
}
EOT
