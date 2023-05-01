#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, etc.
use t_TestCommon ':silent', qw/bug/; # Test::More etc.

use Data::Dumper::Interp;

# Convert a literal "expected" string which contains qr/.../ismx sequences
# into a regex which matches the same string but allows various representations
# of the regex (which differs among Perl versions).
sub expstr2re($) {
  local $_ = shift;
  confess "bug" if ref($_);
  s#/#\\/#g;
  $_ = '\Q' . $_ . '\E';
  s#([\$\@\%])#\\E\\$1\\Q#g;
  s#qr\\/([^\/]+)\\/([msixpodualngcer]*)
   #\\E\(qr\\/$1\\/$2|qr\\/\\(\\?\\^$2:$1\\)\\/\)\\Q#xg
    or confess "No qr/.../ found in input string";
  my $saved_dollarat = $@;
  my $re = eval "qr/${_}/"; die "$@ " if $@;
  $@ = $saved_dollarat;
  $re
}

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
  my $item = {C => {a => 1}};
  my $expected = '{C => {a => 1}}';
  is( Data::Dumper::Interp->new()->Foldwidth($fw)->vis($item), $expected, "fw=$fw" );
  is(                    visnew()->Foldwidth($fw)->vis($item), $expected, "fw=$fw" );
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
      a =>
        1
    }
}
EOF
}
for my $fw (1..5) {
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

like( Data::Dumper::Interp->new()->Foldwidth(72) 
     ->vis({ "" => "Emp", A=>111,BBBBB=>222,C=>{d=>888,e=>999},D=>{},EEEEEEEEEEEEEEEEEEEEEEEEEE=>\42,F=>\\\43, G=>qr/foo.*bar/xsi}),
    expstr2re(do{chomp($_=<<'EOF'); $_}) );
{
  "" => "Emp",A => 111,BBBBB => 222,C => {d => 888,e => 999},D => {},
  EEEEEEEEEEEEEEEEEEEEEEEEEE => \42,F => \\\43,G => qr/foo.*bar/six
}
EOF

# $Foldwidth is 12

is( vis [12345678,4], '[12345678,4]' );

is( vis [123456789,4], do{chomp(local $_=<<'EOF'); $_} );
[
  123456789,
  4
]
EOF

is( vis {bxxxxxxxxxxxxxxxxxxxxxxxxxbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb=>42},
    do{chomp(local $_=<<'EOF'); $_} );
{
  bxxxxxxxxxxxxxxxxxxxxxxxxxbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
    => 42
}
EOF

is( vis [[[[[[[[[[[[[42]]]]]]]]]]]]],
    do{chomp(local $_=<<'EOF'); $_} );
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
    do{chomp(local $_=<<'EOF'); $_} );
[
  \undef,
  \$VAR1->[0]
]
EOF

# Once hit an assertion
is( dvis('\%{}'), '\%{}' );

# Once hit an assertion
{ my $obj = bless do{ \(my $x = []) },"Foo::Bar";
  like( Data::Dumper::Interp->new()->Foldwidth(0)->vis($obj),
        qr/^\Q$obj\E$/ );
}

# Once caused << "<NQMagic...>0" isn't numeric in scalar assignment >>
# when the apparent reference to a zero was to be replaced by a reference
# to "<NQMagic...>0" in the cloned data.
{ my @ary = (42);
  ok( eval{ vis(\$#ary) }, 'vis(\$#array) did not hit a bug' );
}

## Once hit an assertion
#{ my @data = ( { crc => -1 } );
#  push @data, \@data;
#
#  say "DD normal",
#    Data::Dumper->new([\@data])
#    ->Useqq(1)
#    ->Terse(1)
#    ->Indent(1)
#    ->Quotekeys(0)
#    ->Sparseseen(1)
#    ->Dump;
#
#  my $obj = visnew;
#  $obj->Values([\@data]);
#  say "Hybrid: ", &Data::Dumper::Dump($obj);
#
#  say "vis: ", visnew->Debug(1)->Foldwidth(0)->vis(\@data);
#}
#die "tex";

#say vis bless( do{ \(my $x = []) } );

is( Data::Dumper::Interp->new()->Foldwidth(4)->vis( [ [ ], 12345 ] ),
    do{chomp(local $_=<<'EOF'); $_} );
[
  [],
  12345
]
EOF

done_testing();


