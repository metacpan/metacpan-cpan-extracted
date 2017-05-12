package TestInstrument::memory;

use strict;
use warnings FATAL => 'all';

use Apache::Test qw(-withtestmore);

use Apache2::Const -compile => 'OK';

my $leak;
sub handler : method {
    my ($class, $r) = @_;

    plan $r, tests => 1;
    
    foreach my $i (1..100) {
        my $iter = $i * 100;
        my $foo = "xx"x$iter;
    }
    
    $leak .= "xx"x100_100;
    
    ok(1);
    
    return Apache2::Const::OK;
}

1;
__END__
#PerlInstrument time
PerlInitHandler Apache2::Instrument::Memory
