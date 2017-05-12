package TestInstrument::procview;

use strict;
use warnings FATAL => 'all';

use Apache::Test qw(-withtestmore);

use Apache2::Const -compile => 'OK';

sub handler : method {
    my ($class, $r) = @_;
    
    plan $r, tests => 1;
    
    opendir(my $d, "/tmp");

    while(my $f = readdir($d)) {
        my @s = stat $f;
        open (my $h, "<", "/tmp/$f");
    }
    
    ok(1);
    
    return Apache2::Const::OK;
}

1;
__END__
PerlInitHandler Apache2::Instrument::Strace
