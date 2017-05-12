package AutoCode::Root;
use strict;
use AutoCode::Root0;
our @ISA=qw(AutoCode::Root0);
our $VERSION='0.01';
our $DEBUG;
# our $debug;
use AutoCode::SymbolTableUtils;
use AutoCode::AccessorMaker;

sub _find_super {
    my ($dummy, $method)=@_;
    my $ref=ref($dummy) || $dummy;
    no strict 'refs';

    foreach(@{"$ref\::ISA"}){
        next if $_ eq 'UNIVERSAL';
        return $_ if defined &{"$_\::$method"};
        my $super = _find_super($_, $method);
        return $super if defined $super;
    }
    return undef;
}

sub debug {
    my ($class, $msg)=@_;
    print STDERR "[". ref($class). "]\n$msg\n" 
        unless $AutoCode::Root::DEBUG==0;

}

1;
