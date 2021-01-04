
#! @file
#! @author: Serguei Okladnikov <oklaspec@gmail.com>
#! @date 2015.05.30

use strict;
use Template::Constants qw( :debug );
use Async::Template;
use Test::More;
use lib qw( t/lib ./lib ../lib ../blib/arch );

use FindBin '$Bin';
my $lib = "$Bin/lib";
my $src = "$Bin/tmpl";
unshift @INC, $lib;

my $DEBUG = grep(/^--?d(debug)?$/, @ARGV);

my $tt = Async::Template->new({
   INCLUDE_PATH => $src,
   COMPILE_DIR  => '.',
   DEBUG        => $DEBUG ? DEBUG_PLUGINS : 0,
#  DEBUG        => DEBUG_ALL,
}) || die Template->error();

my $out = '';

my $res = $tt->process('the_start',{},\$out);

my $expect = "The start\n";

ok( $out eq $expect, "result equal expect value");

done_testing;
