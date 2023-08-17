#!perl
# print "1..1\n";
use strict;
use warnings;
use lib './lib';
use vars qw( $DEBUG );
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
use Test::More qw( no_plan );

use Data::Pretty qw(dump);
local $Data::Pretty::DEBUG = $DEBUG;

# Create some structure;
my $h = {af=>15, bf=>bless [1,2], "Foo"};
$h->{cf} = \$h->{af};
#$h->{bf}[2] = \$h;
my( $dump_h, $dump_s );
my @s = eval($dump_h = dump($h, $h, \$h, \$h->{af}));

$dump_s = dump(@s);

# print "not " unless $dump_h eq $dump_s;
# print "ok 1\n";
is( $dump_s => $dump_h );

print "\n\$h = $dump_h;\n" if( $DEBUG );
print "\n\$s = $dump_s;\n" if( $DEBUG );

done_testing();

__END__
