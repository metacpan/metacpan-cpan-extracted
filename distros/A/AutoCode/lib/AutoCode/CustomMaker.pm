package AutoCode::CustomMaker;
use strict;
use AutoCode::ModuleLoader;

sub import {
    my ($pkg, $schema, $type, $prefix)=@_;
    return unless $pkg eq __PACKAGE__; # STOP the child misuse it.
    my $callpkg=caller;
    AutoCode::ModuleLoader->load_schema($schema, $prefix);
    
    my $vp = AutoCode::ModuleLoader->load($type);
    no strict 'refs';
    push @{"$callpkg\::ISA"} , $vp;
}
1;
