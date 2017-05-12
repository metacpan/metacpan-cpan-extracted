#!/usr/local/bin/perl

use lib '..','../blib/lib','../blib/arch';
use Boulder::Store;

BEGIN {	
    unlink <test.db*>;
    $^W = 0; 
}
END { unlink <test.db*>; }

sub test ($$;$) {
    my($num, $true,$msg) = @_; 
    print($true ? "ok $num\n" : "not ok $num $msg\n"); 
} 
my($s,@s,$store);

print "1..29\n";
test 1,$store=new Boulder::Store('test.db',1);
test 2,$s = new Stone (name=>'george',
		       age=>23,
		       sex=>M,
		       address=>{
			   street=>'29 Rockland drive',
			   town=>'Fort Washington',
			   ZIP=>'77777'
			   }
		       );
test 3,$store->write_record($s) ne '';
test 4,$store->write_record(new Stone(name=>'fred',
			     age=>30,
			     sex=>M,
			     address=>{
                                   street=>'19 Gravel Path',
				   town=>'Bedrock',
				   ZIP=>'12345'},
			     phone=>{
				 day=>'111-1111',
				 eve=>'222-2222'
				 }
			     ));
test 5,$store->write_record(new Stone(name=>'andrew',
			     age=>18,
			     sex=>M));
test 6,$store->write_record(new Stone(name=>'gertrude',
			     age=>46,
			     sex=>F));
test 7,$store->write_record(new Stone(name=>'abigail',
			     age=>29,
			     sex=>F));
test 8,$store->write_record(new Stone(name=>'james',
			     age=>34,
			     sex=>M));
test 9,4 == $store->put(new Stone(name=>'angelique',
				  age=>16,
				  sex=>F),
			4);
test 10,5 == $store->put(new Stone(name=>'mabel',
				   age=>16,
				   record_no=>5,
				   sex=>F)
			 );
test 11,$store->add_index('age');
undef $store;

test 12,$store=new Boulder::Store('test.db'=>1);
test 13,$s=$store->get(0);
test 14,$s->index('address.ZIP') eq '77777';
test 15,$s=$store->get(2);
test 16,$s->index('age') == 18;
test 17,$s=$store->get(5);
test 18,$s->index('age') == 16;
test 19,$store->query('sex'=>F) and @s = $store->read_record();
test 20,$s[0]->get('sex') eq 'F';
test 21,@s==3;
test 22,$store->query(eval=>'<age> > 25') and @s = $store->read_record();
$ok = 1;
foreach (@s) {
    undef $ok unless $_->get('age') > 25;
}
test 23,$ok;
test 24,@s==2;
test 25,$store->add_index('name');
test 26,$store->query('name'=>'mabel') and @s = $store->read_record();;
test 27,@s==1;
test 28,$s[0]->get('age') == 16 and $s[0]->get('name') eq 'mabel';
test 29,!($store->query('name'=>'foobar') and @s = $store->read_record());
