#! /usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use v5.20;
use autodie;
use File::Temp;
use Cwd 'abs_path';

my $tmp= File::Temp->newdir();
my $in_cpppp= "$tmp/source.cp";
my $out_c= "$tmp/out.c";
my $out_h= "$tmp/out.h";
my $bin_cpppp= abs_path("$FindBin::RealBin/../bin/cpppp");
sub slurp { open my $fh, '<', $_[0]; $/= undef; <$fh> }
sub spew { open my $fh, '>', $_[0]; $fh->print($_[1]); $fh->close; }
sub run_cpppp {
   my ($args, $data)= @_;
   open(my $cmd, '|-', $^X, $bin_cpppp, @$args);
   $cmd->print($data);
   $cmd->close;
   $?
}

subtest basic_output => sub {
   -e $_ && unlink $_ for $out_c, $out_h;
   is( run_cpppp([ -o => $out_c ], <<END), 0, 'exec cpppp' );
## for (0..2) {
#define THING_\$_ \$_
## }
END
   is( slurp($out_c), "#define THING_0 0\n#define THING_1 1\n#define THING_2 2\n" );
};

subtest split_output => sub {
   -e $_ && unlink $_ for $out_c, $out_h;
   is( run_cpppp([ '--section-out', "public=$out_h", -o => $out_c ], <<END), 0 );
## section PUBLIC;
int foo(int x);
## section PRIVATE;
int foo(int x) { return x + 1; }
END
   is( slurp($out_h), "int foo(int x);\n", 'out.h' );
   is( slurp($out_c), "int foo(int x) { return x + 1; }\n", 'out.c' );
};

subtest splice_output_into_file => sub {
   -e $_ && unlink $_ for $out_c, $out_h;
   spew($out_c, <<END);
Line 1
Line 2
// BEGIN GENERATED_TEXT
// END GENERATED_TEXT
Line 5
END
   is( run_cpppp([ '--section-out', 'public='.$out_c.'@GENERATED_TEXT' ], <<END), 0 );
## section PUBLIC;
Injected line 1
Injected line 2
## section PRIVATE;
Injected line 3
END
   is( slurp($out_c), <<END, 'out.c' );
Line 1
Line 2
// BEGIN GENERATED_TEXT
Injected line 1
Injected line 2
// END GENERATED_TEXT
Line 5
END
   is( run_cpppp([ '-o', $out_c.'@GENERATED_TEXT' ], ''), 0 );
   is( slurp($out_c), <<END, 'out.c' );
Line 1
Line 2
// BEGIN GENERATED_TEXT
// END GENERATED_TEXT
Line 5
END
};

subtest convert_comments => sub {
   -e $_ && unlink $_ for $out_c, $out_h;
   is( run_cpppp([ '--convert-linecomment-to-c89', '-o', $out_c ], <<END), 0 );
/* unaffected
 */
int main() { // main function
   // first line of main function
   int i= 0; /* unaffected */
   return i; // second line
}
END
   is( slurp($out_c), <<END, 'out.c' );
/* unaffected
 */
int main() { /* main function */
   /* first line of main function */
   int i= 0; /* unaffected */
   return i; /* second line */
}
END
};

subtest format_commandline => sub {
   -e $_ && unlink $_ for $out_c, $out_h;
   is( run_cpppp([ '--convert-linecomment-to-c89', '-o', $out_c ], <<'END'), 0 );
## use CodeGen::Cpppp::Template 'format_commandline';
/*
${{ format_commandline() }}
*/
END
   is( slurp($out_c), <<END, 'out.c' );
/*
$bin_cpppp --convert-linecomment-to-c89 \\
      -o $out_c
*/
END
};

subtest re_exec => sub {
   $^O eq 'Win32' and skip_all("re_exec doesn't work on Win32");
   -e $_ && unlink $_ for $in_cpppp, $out_c, $out_h;
   spew($in_cpppp, <<END);
#! $^X $bin_cpppp
## main::re_exec("-o", "$out_c", __FILE__)
##  if \@main::original_argv == 1 && \$main::original_argv[0] eq __FILE__;
## use CodeGen::Cpppp::Template 'format_commandline';
/*
\${{ format_commandline() }}
*/
END
   is( run_cpppp([ $in_cpppp ]), 0, 'run_cpppp' );
   is( slurp($out_c), <<END, 'out.c' );
/*
$bin_cpppp -o $out_c \\
      $in_cpppp
*/
END
};

done_testing;
