#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, etc.
use t_TestCommon ':silent', qw/bug $debug t_ok t_is t_like/; # Test2::V0 etc.

use Data::Dumper::Interp;
$Data::Dumper::Interp::Debug = $debug if $debug;

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

$Data::Dumper::Interp::Foldwidth = 12;

t_is( vis undef, 'undef' );
t_is( vis \undef, '\\undef' );
t_is( vis \\undef, '\\\\undef' );

t_is( vis 123, '123' );
t_is( vis \123, '\\123' );
t_is( vis \\123, '\\\\123' );

t_is( vis { aaa => 12 }, '{aaa => 12}' );
t_is( vis { aaa => 123 }, '{aaa => 123}' );
t_is( vis { aaa => 1234 }, do{chomp(my $str=<<'EOF'); $str} );
{
  aaa =>
    1234
}
EOF

t_is( vis { aaa => \1 }, '{aaa => \\1}' );
t_is( vis { aaa => \12 }, '{aaa => \\12}' );
t_is( vis { aaa => \\12 }, do{chomp(my $str=<<'EOF'); $str} );
{
  aaa =>
    \\12
}
EOF
t_is( vis { aaa => \\\12 }, do{chomp(my $str=<<'EOF'); $str} );
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

t_like( Data::Dumper::Interp->new()->Foldwidth(72) 
     ->vis({ "" => "Emp", A=>111,BBBBB=>222,C=>{d=>888,e=>999},D=>{},EEEEEEEEEEEEEEEEEEEEEEEEEE=>\42,F=>\\\43, G=>qr/foo.*bar/xsi}),
    expstr2re(do{chomp($_=<<'EOF'); $_}) );
{
  "" => "Emp",A => 111,BBBBB => 222,C => {d => 888,e => 999},D => {},
  EEEEEEEEEEEEEEEEEEEEEEEEEE => \42,F => \\\43,G => qr/foo.*bar/six
}
EOF

# $Foldwidth is 12

t_is( vis [12345678,4], '[12345678,4]' );

t_is( vis [123456789,4], do{chomp(local $_=<<'EOF'); $_} );
[
  123456789,
  4
]
EOF

t_is( vis {bxxxxxxxxxxxxxxxxxxxxxxxxxbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb=>42},
    do{chomp(local $_=<<'EOF'); $_} );
{
  bxxxxxxxxxxxxxxxxxxxxxxxxxbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
    => 42
}
EOF

t_is( vis [[[[[[[[[[[[[42]]]]]]]]]]]]],
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

# Recursive structures
{ my $debug = 0 || $debug;
  my %hash;
  my @orig_a = (100, \%hash, 900);
  my $x = \@orig_a;
  $hash{aaa} = \$x;
  $hash{bbb} = \$orig_a[2];
  $orig_a[3] = \$orig_a[1];
  $orig_a[4] = $orig_a[1]; # i.e. \%hash
  local $Data::Dumper::Interp::addrvis_ndigits = 5
    unless $Data::Dumper::Interp::addrvis_ndigits > 5;
  #use Readonly ();
  #Readonly::Array my @a => (@$x); my $aref = \@a;
  my $aref = \@orig_a;
  if ($debug) {
    note '\\@$aref = ',Data::Dumper::Interp::_dbrvis(\@$aref);
    note '$x = ',Data::Dumper::Interp::_dbrvis($x);
    note '$aref->[1] = ',Data::Dumper::Interp::_dbrvis($aref->[1]);
    note '$aref->[1]->{aaa} = ',Data::Dumper::Interp::_dbrvis($aref->[1]->{aaa});
    note '$aref->[2] = ',Data::Dumper::Interp::_dbrvis($aref->[2]);
    note '$aref->[3] = ',Data::Dumper::Interp::_dbrvis($aref->[3]);
  }
  is( visnew->Foldwidth(20)->Debug($debug)->vis($aref), do{chomp(local $_=<<'EOF'); $_}, "big recursive structure" );
[
  100,
  {
    aaa => \$VAR1,
    bbb => \900
  },
  ${$VAR1->[1]{bbb}},
  \$VAR1->[1],
  $VAR1->[1]
]
EOF
}

# Once hit an assertion
t_is( vis [ \undef, \\undef ],
    do{chomp(local $_=<<'EOF'); $_}, "recursive structure" );
[
  \undef,
  \$VAR1->[0]
]
EOF

# Once hit an assertion
t_is( dvis('\%{}'), '\%{}' );

# Once hit an assertion
{ my $obj = bless do{ \(my $x = []) },"Foo::Bar";
  t_like( Data::Dumper::Interp->new()->Foldwidth(0)->vis($obj),
          qr/^\Q$obj\E$/ );
}

# Once caused "UNPARSED !!0" (with perl 5.37.10 & D::D 2.188)
t_like( vis(!!undef), qr/^(?:!!0|"")$/, "vis(!!undef)" );
t_like( vis(!!0),     qr/^(?:!!0|"")$/, "vis(!!0)" );
t_like( vis(!!1),     qr/^(?:!!1|1)$/, "vis(!!1)" );

# Once caused << "<NQMagic...>0" isn't numeric in scalar assignment >>
# when the apparent reference to a zero was to be replaced by a reference
# to "<NQMagic...>0" in the cloned data.
{ my @ary = (42);
  t_ok( eval{ vis(\$#ary) }, 'vis(\$#array) did not hit a bug' )
    || diag "Eval error: $@";
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

t_is( Data::Dumper::Interp->new()->Foldwidth(4)->vis( [ [ ], 12345 ] ),
    do{chomp(local $_=<<'EOF'); $_} );
[
  [],
  12345
]
EOF

done_testing();


