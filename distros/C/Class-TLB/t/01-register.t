#!perl -T

use Test::More tests =>  15 ;

use Data::Dumper ;

BEGIN {
	use_ok( 'Class::TLB' );
        use_ok( 'Class::TLB::Dummy');
}

my $tlb = new_ok( 'Class::TLB' );

eval{
    $tlb->tlb_register();
};
if( $@ ){
    pass('void register');
}else{
    fail('void register');
}

ok( $tlb->isa('Class::TLB') ,  'Class::TLB isa is correct');
ok( $tlb->can('tlb_register') , 'Class::TLB can is correct');

foreach my $i ( 1 .. 3 ){
    $tlb->tlb_register(Class::TLB::Dummy->new($i)) ;
}

ok( $tlb->isa('Class::TLB::Dummy') ,  'After registration , is a TLB::Dummy');
ok( ! $tlb->can('tlb_register') , 'can no longer tlb methods');
ok( $tlb->can('doSomething') , 'After registration it acts like a TLB::Dummy');

is($tlb->tlb_class() , 'Class::TLB::Dummy' , 'resource class ok');


my $s1 = $tlb->doSomething() ;

cmp_ok($s1, 'eq', 'I (1) did something', "First call");

my $s2 = $tlb->doSomething() ;

cmp_ok($s2, 'eq', 'I (2) did something', "Second call");

my $s3 =  $tlb->doSomething() ;

cmp_ok($s3 , 'eq', 'I (3) did something', "Third call");

my $error = '' ;
eval{
    $tlb->doFail() ;
};
if ( $@ ){ $error = $@ ;}
ok( $error =~ /^Arghhh/ , 'Correct error of failed method');

my $failH = {} ;
for( my $i = 0 ; $i < 1000 ; $i++ ){
    $failH->{$tlb->oneFail()} ++ ;
}

my @failKeys = keys %$failH ;


ok( join(',' , @failKeys) !~ 'I am 1' , "1 has always fail" );

#diag("Resources usage on test:\n\n ". Dumper($tlb->tlb_usecount()));
