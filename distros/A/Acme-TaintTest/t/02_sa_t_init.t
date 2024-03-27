#!/usr/bin/perl -T

# set up some things the way t/SATest.pm in Mail::SpamAssassin does
# to try to duplicate whatever causes the taint failures we are looking for
# The failures didn't happen without any of this stuff.
use lib '.'; use lib 't';
use SATest; sa_t_init("02_sa_t_init");

use strict;
use warnings;
require v5.14.0;

use Scalar::Util qw(tainted);
use Cwd;
use Carp;
use File::Spec;
use File::Temp qw(tempdir);

use Test::More;
plan tests => 10;

diag("\nINC for tests is '@INC'\nPATH is $ENV{'PATH'}\n");

# some CPAN test machines get strange taint errors in Mail::SpamAssassin tests
# This is an attempt to isolate the problem in a series of simpler tests that
# might cause the same effect.

my @CHARS = (qw/ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
                 a b c d e f g h i j k l m n o p q r s t u v w x y z
                 0 1 2 3 4 5 6 7 8 9 _
               /);

my $dir = 'log';
ok(!tainted($dir), '$dir');
my $tname = 'tainttests';
ok(!tainted($tname), '$template');
my $template = "$tname.XXXXXX";
ok(!tainted($template), '$template');
my ($volume, $directories, undef) = File::Spec->splitpath( $template, 1);
ok(!tainted($directories), '$directories from splitpath');
my $template2 = (File::Spec->splitdir($directories))[-1];
ok(!tainted($template2), '$template2 from splitdir');
my $template3 = File::Spec->catdir($dir, $template2);
ok(!tainted($template3), '$template3 from catdir');
my $path = File::Temp::_replace_XX($template3, 0);
ok(!tainted($path), '$path from _replace_XX');
my $path2 = $template3;
ok(!tainted($path2), '$path2 same as $template3');
$path2 =~ s/X(?=X*\z)/$CHARS[ int( rand( @CHARS ) ) ]/ge;
ok(!tainted($path2), '$path2 after regex with rand');

ok(tempdir("$tname.XXXXXX", DIR => "log"), 'call File::Temp::tempdir');
