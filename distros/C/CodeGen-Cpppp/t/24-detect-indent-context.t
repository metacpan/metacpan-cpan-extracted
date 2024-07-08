#! /usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use CodeGen::Cpppp;

my $cpppp= CodeGen::Cpppp->new;

my @tests= (
   {  name => "twospace",
      code => unindent(<<'C'), file => __FILE__, line => __LINE__,
      int foo(int i) {
        twospace();
      }
C
      expect => '  ',
   },
   {  name => "threespace",
      code => unindent(<<'C'), file => __FILE__, line => __LINE__,
      struct vec {
         int a,
             b,
             c,
             d;
      };
      const int x[]=
       {
         1, 2, 3, 4
       };
C
      expect => '   ',
   },
   {  name => "fourspace",
      code => unindent(<<'C'), file => __FILE__, line => __LINE__,
      int somefunction(int a, int b, int c,
        int d, int e)
      {
          code();
          if (x)
            {
              more_code();
            }
      }
C
      expect => '    ',
   },
   {  name => 'tabs',
      file => __FILE__, line => __LINE__, code =>
       "struct vec {\n"
      ."\tfloat x,\n"
      ."\t      y,\n"
      ."\t      z;\n"
      ."};",
      expect => "\t",
   },
);

for my $t (@tests) {
   my $parse= $cpppp->parse_cpppp(\$t->{code}, $t->{file}, $t->{line}+1);
   is( $parse->{indent}, $t->{expect}, $t->{name} )
      or note explain($parse);
}

done_testing;
