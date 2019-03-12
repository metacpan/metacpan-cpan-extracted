use strict;
use JavaScript::Duktape::XS;

warn "$$ started";
my $i = 0;
my $vm;

while () {
    $vm = make_vm() unless  $i % 1_000;
    $vm->eval("validator_$i = new xx();");
    $vm->remove("validator_$i");
    $vm->run_gc();
    $i++;
}

sub make_vm {
    warn "Instantiating a new VM";
    my $nvm = JavaScript::Duktape::XS->new();
    $nvm->eval("function xx (){ this.abc = 'camel'; this.circular = this; }");
    return $nvm;
}