require Class::Eroot;


{ package OBJ;
	sub new {
		local $x = 0;
		bless \$x;
	}
}


local $a;
local $eroot = new EROOT ( 'Name' => "/tmp/test", 'Key' => 'myApp' );

if( $eroot->Continue ){
	$a = new OBJ;
	$eroot->Keep( "myObj" => $a );
}
else {
	$a = $eroot->Root( "myObj" );
}


print "a=$$a\n";
++$$a;
1;
