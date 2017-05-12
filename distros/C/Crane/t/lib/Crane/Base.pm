# -*- coding: utf-8 -*-


package t::lib::Crane::Base;


use Crane::Base qw( Exporter );

use Test::More;


our @EXPORT = qw(
    &test_base
);


sub test_base {
    
    plan('tests' => 1);
    
    isa_ok(__PACKAGE__, 'Exporter');
    
    return done_testing();
    
}


1;
