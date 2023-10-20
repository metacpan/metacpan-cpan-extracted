#! /usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use CodeGen::Cpppp;

my $cpppp= CodeGen::Cpppp->new;

my @tests= (
   {  name => "simple",
      code => unindent(<<'C'), file => __FILE__, line => __LINE__,
      ## my @items= (1,2,3);
      ## sub items_list { @items }
      ## sub set_items { @items= @_ }
C
      expect => object {
         call sub { [ shift->set_items(4,3,2) ] } => [ 4,3,2 ];
         call sub { [ shift->items_list ] } => [ 4,3,2 ];
      }
   },
);

for my $t (@tests) {
   subtest $t->{name} => sub {
      my $class= $cpppp->compile_cpppp(\$t->{code}, $t->{file}, $t->{line}+1);
      my $tpl= $class->new();
      is( $tpl, $t->{expect} )
         or note explain($tpl->_parse_data);
   };
}

done_testing;
