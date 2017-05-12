#!perl
use Test::More;
use lib './t/lib' ;
use ObjTest ;

my %defaults = (
	'array'		=> [],	
	'hash'		=> {},	
	'notdef'	=> undef,
	'string'	=> 'test string',
) ;
my %set = (
	'array'		=> [qw/one two three four/],	
	'hash'		=> {
		'a'		=> 'value1',
		'b'		=> 'value2',
		'c'		=> 'value3',
		'd'		=> 'value4',
	},	
	'notdef'	=> 1234,
	'string'	=> 'a different string',
) ;

	plan tests => 1 
		+ scalar(keys %defaults)
		+ scalar(keys %set)
		+ scalar(keys %defaults)
		+ scalar(keys %set)
	;		
	
	my $obj = ObjTest->new() ;
	ok($obj, "Created object") ;
$obj->prt_data("New object=", $obj) ;
	
	foreach my $key (keys %defaults)
	{
		my $val = $obj->$key ;
		is_deeply($val, $defaults{$key}, "Default for $key") ;
	}
	
	$obj->set(%set) ;
	foreach my $key (keys %set)
	{
		my $val = $obj->$key ;
		is_deeply($val, $set{$key}, "Set for $key") ;
	}
	
	$obj->set(%defaults) ;
	foreach my $key (keys %defaults)
	{
		my $val = $obj->$key ;
		is_deeply($val, $defaults{$key}, "Default for $key") ;
	}
	
	foreach my $key (keys %set)
	{
		$obj->$key($set{$key}) ;
		my $val = $obj->$key ;
		is_deeply($val, $set{$key}, "Set for $key") ;
	}
	
	
	