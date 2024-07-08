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
   {  name => "method_with_template",
      code => unindent(<<'C'), file => __FILE__, line => __LINE__,
      ## sub define_wrapper($sub_namespace, $obj_t) {
      extern int ${sub_namespace}_process_${obj_t}($obj_t *obj);
      ## }
C
      expect => object {
         call output => "";
         call sub { [ shift->define_wrapper('example_x', 'float') ] } => D;
         call output => "extern int example_x_process_float(float *obj);\n";
         call sub { [ shift->define_wrapper('example_y', 'double') ] } => D;
         call output => "extern int example_x_process_float(float *obj);\n"
                       ."extern int example_y_process_double(double *obj);\n";
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
