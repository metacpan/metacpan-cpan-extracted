#!/usr/bin/perl
use strict; use warnings  FATAL => 'all'; use feature qw(state say); use utf8;
srand(42);  # so reproducible
use open IO => ':locale';
select STDERR; $|=1; select STDOUT; $|=1;
use Carp;

use Test::More;

use Data::Dumper::Interp;

#$Data::Dumper::Interp::Debug = 1;
$Data::Dumper::Interp::Foldwidth = 12;

is( vis undef, 'undef' );
is( vis \undef, '\\undef' );
is( vis \\undef, '\\\\undef' );

is( vis 123, '123' );
is( vis \123, '\\123' );
is( vis \\123, '\\\\123' );

is( vis { aaa => 12 }, '{aaa => 12}' );
is( vis { aaa => 123 }, '{aaa => 123}' );
is( vis { aaa => 1234 }, do{chomp(my $str=<<'EOF'); $str} );
{
  aaa =>
    1234
}
EOF

is( vis { aaa => \1 }, '{aaa => \\1}' );
is( vis { aaa => \12 }, '{aaa => \\12}' );
is( vis { aaa => \\12 }, do{chomp(my $str=<<'EOF'); $str} );
{
  aaa =>
    \\12
}
EOF
is( vis { aaa => \\\12 }, do{chomp(my $str=<<'EOF'); $str} );
{
  aaa =>
    \\\12
}
EOF

for my $fw (15..17) {
  is( Data::Dumper::Interp->new()->Foldwidth($fw)->vis({C => {a => 1}}), '{C => {a => 1}}', "fw=$fw" );
}
for my $fw (12..14) {
  is( Data::Dumper::Interp->new()->Foldwidth($fw)->vis({C => {a => 1}}), do{chomp($_=<<'EOF'); $_}, "fw=$fw" );
{
  C =>
    {a => 1}
}
EOF
}
for my $fw (10..11) {
  is( Data::Dumper::Interp->new()->Foldwidth($fw)->vis({C => {a => 1}}), do{chomp($_=<<'EOF'); $_}, "fw=$fw" );
{
  C =>
    {
      a =>
        1
    }
}
EOF
}
for my $fw (6..9) {
  is( Data::Dumper::Interp->new()->Foldwidth($fw)->vis({C => {a => 1}}), do{chomp($_=<<'EOF'); $_}, "fw=$fw" );
{
  C =>
    {
      a
        =>
        1
    }
}
EOF
}
for my $fw (1..5) {
  is( Data::Dumper::Interp->new()->Foldwidth($fw)->vis({C => {a => 1}}), do{chomp($_=<<'EOF'); $_}, "fw=$fw" );
{
  C
    =>
    {
      a
        =>
        1
    }
}
EOF
}

is( Data::Dumper::Interp->new()->Foldwidth(72)
     ->vis({ "" => "Emp", A=>111,BBBBB=>222,C=>{d=>888,e=>999},D=>{},EEEEEEEEEEEEEEEEEEEEEEEEEE=>\42,F=>\\\43, G=>qr/foo.*bar/xsi}), 
     do{chomp($_=<<'EOF'); $_} );
{ "" => "Emp",A => 111,BBBBB => 222,C => {d => 888,e => 999},D => {},
  EEEEEEEEEEEEEEEEEEEEEEEEEE => \42,F => \\\43,G => qr/foo.*bar/six
}
EOF


is( vis [12345678,4], '[12345678,4]' );

is( vis [123456789,4], do{chomp(my $_=<<'EOF'); $_} );
[ 123456789,
  4
]
EOF

is( vis {bxxxxxxxxxxxxxxxxxxxxxxxxxbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb=>42},
    do{chomp(my $_=<<'EOF'); $_} );
{
  bxxxxxxxxxxxxxxxxxxxxxxxxxbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
    => 42
}
EOF

is( vis [[[[[[[[[[[[[42]]]]]]]]]]]]],
    do{chomp(my $_=<<'EOF'); $_} );
[
  [
    [
      [
        [
          [
            [
              [
                [
                  [
                    [
                      [
                        [
                          42
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ]
]
EOF

# Once hit an assertion
is( vis [ \undef, \\undef ],
    do{chomp(my $_=<<'EOF'); $_} );
[ \undef,
  \$VAR1->[0]
]
EOF

# Once hit an assertion
is( dvis('\%{}'), '\%{}' );

# Once hit an assertion
is( Data::Dumper::Interp->new()->Foldwidth(0)
     ->vis(bless do{ \(my $x = []) }), q<bless(do{\(my $o = [])},'main')> );

#say vis bless( do{ \(my $x = []) } );

is( Data::Dumper::Interp->new()->Foldwidth(4)->vis( [ [ ], 12345 ] ),
    do{chomp(my $_=<<'EOF'); $_} );
[
  [
  ],
  12345
]
EOF


done_testing();


