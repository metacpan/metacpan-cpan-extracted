package TestInstrument::time;

use strict;
use warnings FATAL => 'all';

use Apache::Test qw(-withtestmore);

use Apache2::Const -compile => 'OK';

sub handler : method {
    my ($class, $r) = @_;
    
    plan $r, tests => 1;
    
    sleep(2);
    
    ok(1);
    
    return Apache2::Const::OK;
}

1;
__END__
#PerlInstrument time
PerlInitHandler Apache2::Instrument::Time
