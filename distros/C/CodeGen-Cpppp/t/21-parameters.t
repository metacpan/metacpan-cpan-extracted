#! /usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use CodeGen::Cpppp;

my $cpppp= CodeGen::Cpppp->new;

my @tests= (
   {  name => "scalar",
      code => unindent(<<'C'), file => __FILE__, line => __LINE__,
      ## param $x= 10;
      $x
      ## $x= 7;
C
      tests => [
         { params => {},             expect => "10\n", final => 7, name => 'x default' },
         { params => { x => undef }, expect => "\n",   final => 7, name => 'x=undef' },
         { params => { x => 5 },     expect => "5\n",  final => 7, name => 'x=5' },
      ]
   },
   { name => 'array',
      code => unindent(<<'C'), file => __FILE__, line => __LINE__,
      ## param @x= ( 1, 2, 3 );
      (@x)
      ## @x= (7);
C
      tests => [
         { params => {},             expect => "(1, 2, 3)\n", final => [7], name => 'x default' },
         { params => { x => undef }, error => qr/array/i,                   name => 'x=undef' },
         { params => { x => [5,6] }, expect => "(5, 6)\n",    final => [7], name => 'x=[5,6]' },
      ]
   },
   { name => 'hash',
      code => unindent(<<'C'), file => __FILE__, line => __LINE__,
      ## param %x= ( a => 1 );
      $_: $x{$_} ## for sort keys %x;
      ## %x= ( a => 7 );
C
      tests => [
         { params => {},                  expect => "a: 1\n",       final => {a=>7}, name => 'x default' },
         { params => { x => undef },      error => qr/hash/i,                        name => 'x=undef' },
         { params => { x => {b=>6}},      expect => "b: 6\n",       final => {a=>7}, name => 'x={b=>6}' },
         { params => { x => {c=>1,d=>2}}, expect => "c: 1\nd: 2\n", final => {a=>7}, name => 'x={c=>1,d=>2}' },
      ]
   },
);

for my $t (@tests) {
   subtest $t->{name} => sub {
      my $class= $cpppp->compile_cpppp(\$t->{code}, $t->{file}, $t->{line}+1);
      for my $t2 (@{$t->{tests}}) {
         my $tpl= eval { $class->new($t2->{params}) };
         my $err= $@;
         if ($t2->{error}) {
            ok( !defined $tpl, "constructor throws exception $t2->{name}" );
            like( $err, $t2->{error}, "exception text $t2->{name}" );
         } else {
            diag $err if defined $err && length $err;
            ok( defined $tpl, "new template $t2->{name}" );
            is( $tpl->output->get, $t2->{expect}, "output $t2->{name}" );
            is( $tpl->x, $t2->{final}, "final value $t2->{name}" )
               or note explain($tpl);
         }
      }
   };
}

done_testing;
