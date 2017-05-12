use strict;
use Test;
BEGIN { plan tests => 5 }
use Config::Natural;
Config::Natural->options(-quiet => 1);

sub space2underscore {
    my $self = shift;
    my $data = shift;
    $data =~ s/^(\w+) (\w+)/${1}_$2/;
    return $data
}

my $obj = new Config::Natural {
        affectation_symbol => ':',
        quiet => 1,
    };

# First, we check that the prefilter is present.
$obj->prefilter(\&space2underscore);
ok( ref $obj->{'prefilter'}, 'CODE' );  #01

# Reading the data.
$obj->read_source(\*DATA);

# Now we check that it has worked as expected. 
ok( $obj->param('cpu_family'), 6                );  #02
ok( $obj->param('model_name'), 'AMD Athlon(tm)' );  #03
ok( $obj->param('cache_size'), '256 KB'         );  #04
ok( $obj->param('cpuid_level'), 1               );  #05

__END__

# copy-paste from the /proc/cpuinfo of my Linux machine
processor       : 0
vendor_id       : AuthenticAMD
cpu family      : 6
model           : 8
model name      : AMD Athlon(tm)
stepping        : 0
cpu MHz         : 1342.804
cache size      : 256 KB
fdiv_bug        : no
hlt_bug         : no
f00f_bug        : no
coma_bug        : no
fpu             : yes
fpu_exception   : yes
cpuid level     : 1
wp              : yes
flags           : fpu vme de tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 mmx fxsr sse syscall mmxext 3dnowext 3dnow
bogomips        : 2680.42
