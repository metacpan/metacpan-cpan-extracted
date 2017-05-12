#!/usr/local/bin/perl -w

use lib '..','../blib/lib','../blib/arch';
use Boulder::Stream;
BEGIN {	
    unlink "test.stream";
    $^W = 0; 
}
END { unlink "test.stream"; }

sub test ($$;$) {
    my($num, $true,$msg) = @_; 
    print($true ? "ok $num\n" : "not ok $num $msg\n"); 
} 
my($s,@s);

open (OUT,">test.stream");

print "1..20\n";

test 1,$stream = new Boulder::Stream(\*STDIN,\*OUT);
test 2,$s = new Stone;
test 3,$s = new Stone(name=>'fred',age=>30);
test 4,join(' ',sort $s->tags) eq 'age name';

$s->insert(sex=>M);
test 5,join(' ',sort $s->tags) eq 'age name sex';

$s->insert(address=>{
                     street=>'19 Gravel Path',
		     town=>'Bedrock',
		     ZIP=>'12345'},
	   phone=>{
	       day=>'111-1111',
	       eve=>'222-2222'
	   }
	   );

test 6,join(' ',sort $s->tags) eq 'address age name phone sex';

$s->delete('sex');
test 7,join(' ',sort $s->tags) eq 'address age name phone';
		
test 8,$s->get('age') == 30;
test 9,ref($s->get('address')) eq 'Stone';
test 10,$s->get('address')->get('town') eq 'Bedrock';
test 11,$s->index('phone.day') eq '111-1111';

$s->get('phone')->insert('day'=>'999-9999');
test 12,scalar(@s = $s->index('phone.day')) == 2;
test 13,join(' ',sort(@s)) eq '111-1111 999-9999';

test 14,$stream->put($s);
$s = new Stone (name=>'george',
		age=>23,
		address=>{
		    street=>'29 Rockland drive',
		    town=>'Fort Washington',
		    ZIP=>'77777'
		    }
		);
test 15,$stream->put($s);
close OUT;

test 16,open(IN,"test.stream");
test 17,$stream = new Boulder::Stream(\*IN,\*STDOUT);
$s = $stream->get;
test 18,join(' ',sort($s->index('phone.day'))) eq '111-1111 999-9999';
$s = $stream->get;
test 19,$s->index('address.town') eq 'Fort Washington';
test 20,!$stream->get;

