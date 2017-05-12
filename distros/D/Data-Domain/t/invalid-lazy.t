#!perl

use Test::More tests => 4;
use Data::Dumper;

BEGIN { use_ok( 'Data::Domain', qw/:all/ ); }

my $dom;


#----------------------------------------------------------------------
# context and lazy constructors
#----------------------------------------------------------------------

$dom = Struct(
  d_begin => Date,
  d_end   => sub {  my $context = shift;
                    Date(-min => $context->{flat}{d_begin}) },
 );

ok(!$dom->inspect({d_begin => '01.01.2001', 
                   d_end   => '02.02.2002'}), "Dates order ok");

ok($dom->inspect({d_begin => '03.03.2003', 
                   d_end   => '02.02.2002'}), "Dates order fail");

my $r = $dom->inspect({d_begin => 'foo_bar', 
                       d_end   => '02.02.2002'});

is_deeply ($r,
           {d_begin => 'Date: invalid date',
            d_end   => 'domain parameters: invalid date (-min): foo_bar '},
           "Invalid lazy domain");

