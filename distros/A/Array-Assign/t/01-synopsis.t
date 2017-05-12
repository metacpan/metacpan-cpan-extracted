#!/usr/bin/perl
use strict;
use warnings;
use Array::Assign;
use Test::More;
{
    diag "Synopsis (Procedural)";
    my @array;
   arry_assign_i @array, 4 => "Fifth", 0 => "First";
   ok $array[4] eq "Fifth" && $array[0] eq "First";
   
   my $mappings = { fifth => 4, second => 1 };
   
   arry_assign_s @array, $mappings, fifth => "hi", second => "bye";
   ok $array[4] eq "hi" && $array[1] eq "bye";
   
   my ($fooval,$bazval);
   
   my @arglist = qw(first foo bar baz);
   arry_extract_i @arglist, 3 => \$bazval, 1 => \$fooval;
   ok $fooval eq "foo" && $bazval eq "baz";
   
   my $emapping = { foovalue => 1, bazvalue => 3 };
   arry_extract_s @arglist, $emapping, foovalue => \$fooval, bazvalue => \$bazval;
   ok $fooval eq 'foo' && $bazval eq 'baz';

}
{
    my @array;
    my $assn = Array::Assign->new(qw(foo bar baz));
    $assn->assign_s(\@array, foo => "hi", baz => "bye");
    ok($array[0] eq 'hi' && $array[2] eq 'bye');
    
    $assn->assign_i(\@array, 0 => "first", 2 => "last");
    ok($array[0] eq 'first' && $array[2] eq 'last');
    
    my ($firstval,$lastval);
    $assn->extract_s(\@array, foo => \$firstval, baz => \$lastval);
    ok($firstval eq 'first' && $lastval eq 'last');
    $assn->extract_i(\@array, 2 => \$lastval, 0 => \$firstval);
    ok($firstval eq 'first' && $lastval eq 'last');
}
done_testing();