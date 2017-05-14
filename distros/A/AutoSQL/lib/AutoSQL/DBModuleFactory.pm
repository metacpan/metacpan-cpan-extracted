package AutoSQL::DBModuleFactory;
use strict;
use AutoCode::ModuleFactory;

our @ISA=qw(AutoCode::ModuleFactory);

sub make_module {
    my $class=shift;
    $class->SUPER::make_module(shift, 'AutoSQL::DBObject');
    
}

1;
