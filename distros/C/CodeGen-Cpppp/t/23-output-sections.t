#! /usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use CodeGen::Cpppp;

my $cpppp= CodeGen::Cpppp->new;
my $class= $cpppp->compile_cpppp(\<<'C', __FILE__, __LINE__+1);
## section PUBLIC;
struct Example;
extern int example(struct Example *);
## section PROTECTED;
struct Example {
   int a;
};
## section PRIVATE;
int example(struct Example *e) {
   (void)e;
}
C

my $tpl= $class->new;
is( $tpl->output, object {
   call [ get => 'public' ], "struct Example;\nextern int example(struct Example *);\n";
   call [ get => 'protected' ], "struct Example {\n   int a;\n};\n";
   call [ get => 'private' ], "int example(struct Example *e) {\n   (void)e;\n}\n";
});

is( '' . $tpl->output, 
   "struct Example;\nextern int example(struct Example *);\n"
   ."struct Example {\n   int a;\n};\n"
   ."int example(struct Example *e) {\n   (void)e;\n}\n"
);

done_testing;
