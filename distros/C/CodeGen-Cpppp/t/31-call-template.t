#! /usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use CodeGen::Cpppp;

my $cpppp= CodeGen::Cpppp->new(
   include_path => $FindBin::RealBin . '/../example',
);

my $tpl_class= $cpppp->compile_cpppp(\<<'C', __FILE__, __LINE__);
## template("vector.cp", el_t => 'long')->flush;
## template("vector.cp", el_t => 'double')->flush;
## template("vector.cp", el_t => 'void*')->flush;
C

my $out= $cpppp->new_template($tpl_class)->output;
my $header= $out->get('public');
like($header, qr/\Qbool vector_long_realloc(vector_long_t **vec_p, size_t capacity);\E\n/ );
like($header, qr/\Qbool vector_double_realloc(vector_double_t **vec_p, size_t capacity);\E\n/ );
like($header, qr/\Qbool vector_void_p_realloc(vector_void_p_t **vec_p, size_t capacity);\E\n/ );

done_testing;
