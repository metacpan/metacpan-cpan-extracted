use lib 'blib/lib';
use warnings;
use strict;
use Test::More tests => 15;
use 5.008001;
BEGIN { use_ok('Convert::Moji') };

use Convert::Moji;
use utf8;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
binmode Test::More->builder->output, ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

my %rot13;
@rot13{('a'..'m')} = ('n'..'z');

my $moji = Convert::Moji->new(["table",\%rot13]);
#print $moji->convert ("abcdefg"),"\n";
ok ($moji->convert ("abcdefg") eq "nopqrst", "basic test");
#print $moji->invert ("nopqrst"),"\n";
ok ($moji->invert ("nopqrst") eq "abcdefg", "basic inversion test");

my %ambiguous;
@ambiguous{('a'..'h')} = ('n'..'q') x 2;

my $moji2 = Convert::Moji->new(["table",\%ambiguous]);

ok ($moji2->convert ("abcdefg") eq "nopqnop", "ambiguous test");
my $all_joined = $moji2->invert ("77no55pq", 'all_joined');
#print "$all_joined\n";
ok ($all_joined eq '77[a e][b f]55[c g][d h]', "inverted all joined");

my $moji3 = Convert::Moji->new(["table",\%rot13],["table",{n=>1,o=>2,p=>3}]);
ok ($moji3, "create double table");
ok ($moji3->convert ("abc") eq '123', "convert with double table");
ok ($moji3->invert ("123") eq 'abc', "invert with double table");
my $moji4 = Convert::Moji->new(["tr","あいうえお", "アイウエオ"]);
ok ($moji4, "create tr converter");
ok ($moji4->convert ("あうお","アウオ"), "tr-based conversion");
ok ($moji4->invert ("アウオ","あうお"), "tr-based conversion");
sub monsterbaby
{
#    print $input;
    my @s = split '';
    my @t = map {"y".$_."x"} @s;
    return join '', @t;
}
my $moji5 = Convert::Moji->new(["code", \&monsterbaby]);
ok ($moji5, "code based convertor");
#print $moji5->convert ("abcd");
ok ($moji5->convert ("abcd") eq "yaxybxycxydx", "subroutine conversion");
my $fname = "poo.txt";
open my $f, ">:utf8", "$fname" or die "can't write file: $!";
print $f <<EOF;
ギ gi
プ pu
EOF
close $f or die "can't close $f: $!\n";
my $moji6 = Convert::Moji->new(["oneway", "file", "$fname"]);
unlink "$fname" or die "can't unlink $fname: $!";
ok ($moji6, "Create converter from file.");
ok ($moji6->convert ("ギプ") eq "gipu", "convert using file");
