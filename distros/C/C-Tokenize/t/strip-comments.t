use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use C::Tokenize 'strip_comments';

my $hairy = <<'EOF';
/* Comment
   Comment
   http://stupid.comment.parsers.think.this.looks.like.a.cplusplus.comment.because.of.the.slashes.but.it.is.not.because.it.is.inside.another.comment */

int x;

/* Communicating sequential processes by C.A.R. Hoare. */

EOF
my $stripped = strip_comments ($hairy);
like ($stripped, qr/int x;/, "Did not accidentally remove stuff");
like ($stripped, qr/(?:\h*\n){4}int x;/, "Preserved line numbering after stripping.");

my $intx = strip_comments ('int/* comment */x');
like ($intx, qr/int\s+x/, "Preserve one space in trad comments");

my $instr = <<'EOF';
char * notacomment = "/* not a comment */";
char * notacxxcomment = "http://www.example.com/";
char * nasty = "\"/* bad stuff here */";
EOF
my $scinstr = strip_comments ($instr);
is ($scinstr, $instr, "Do not remove comments from strings");

my $cxx = <<'EOF';
int x; // delete
char * y = "// keep";
int z; // delete
EOF
my $out = strip_comments ($cxx);
like ($out, qr!// keep!, "keep comments in string");
unlike ($out, qr!// delete!, "delete other comments");

done_testing ();
