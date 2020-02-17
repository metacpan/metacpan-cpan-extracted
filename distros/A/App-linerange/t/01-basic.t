#!perl

use strict;
use warnings;
use Test::More 0.98;

use App::linerange qw(linerange);
use File::Temp qw(tempfile);

my ($fh, $filename) = tempfile();
print $fh "$_\n" for 1..16;
close $fh;
open $fh, "<", $filename or die;

seek $fh, 0, 0; is_deeply(linerange(fh=>$fh, spec=>"1 to 5")->[0], 400, "invalid line range syntax");
seek $fh, 0, 0; is_deeply(linerange(fh=>$fh, spec=>"0..5")->[0] , 400, "line number 0 not allowed (1)");
seek $fh, 0, 0; is_deeply(linerange(fh=>$fh, spec=>"-3..0")->[0], 400, "line number 0 not allowed (2)");
seek $fh, 0, 0; is_deeply(linerange(fh=>$fh, spec=>"/0")->[0], 400, "invalid every syntax");

sub test_linerange {
    my %args = @_;

    $args{args}{fh} = $fh;
    $args{args}{spec} = $args{spec};
    seek $fh, 0, 0;
    my $res = linerange(%{$args{args}});
    is_deeply($res->[2], [map {"$_\n"} @{$args{res}} ], $args{name} // $args{spec})
        or diag explain $res;
}

test_linerange(spec=>"", res=>[1..16]);
test_linerange(spec=>"/1", res=>[1..16]);
test_linerange(spec=>"/2", res=>[2,4,6,8,10,12,14,16]);
test_linerange(spec=>"/3", res=>[3,6,9,12,15]);
test_linerange(spec=>"/5", res=>[5,10,15]);
test_linerange(spec=>"/7", res=>[7,14]);
test_linerange(spec=>"/8", res=>[8,16]);
test_linerange(spec=>"/9", res=>[9]);
test_linerange(spec=>"/16", res=>[16]);
test_linerange(spec=>"/17", res=>[]);

test_linerange(spec=>"1..3"  , res=>[1..3]);
test_linerange(spec=>"1-3"   , res=>[1..3]);
test_linerange(spec=>"1 .. 3", res=>[1..3]);
test_linerange(spec=>"1..3/2", res=>[2]);

test_linerange(spec=>"3..1"  , res=>[1..3]);
test_linerange(spec=>"3..1/2", res=>[2]);

test_linerange(spec=>"1+0" , res=>[1]);
test_linerange(spec=>"1+1" , res=>[1..2]);
test_linerange(spec=>"1+2" , res=>[1..3]);

test_linerange(spec=>"1, 3" , res=>[1, 3]);
test_linerange(spec=>"1, 3, -1" , res=>[1, 3, 16]);

test_linerange(spec=>"-5..-1" , res=>[12..16]);
test_linerange(spec=>"-1..-5" , res=>[12..16]);
test_linerange(spec=>"5..-1" , res=>[5..16]);
test_linerange(spec=>"5..-3" , res=>[5..14]);
test_linerange(spec=>"-3..5" , res=>[5..14]);
test_linerange(spec=>"5..-3, -1" , res=>[5..14, 16]);
test_linerange(spec=>"5..-3, 10..-1", res=>[5..16]);
test_linerange(spec=>"5..-5, -3..-1", res=>[5..12, 14..16]);
test_linerange(spec=>"-1..-5/2" , res=>[13,15]);
test_linerange(spec=>"5..-1/3"  , res=>[7,10,13,16]);

test_linerange(spec=>"-5+0"  , res=>[12]);
test_linerange(spec=>"-5+1"  , res=>[12..13]);
test_linerange(spec=>"-5+-1" , res=>[11..12]);
test_linerange(spec=>"-5+1/2", res=>[13]);

done_testing;
