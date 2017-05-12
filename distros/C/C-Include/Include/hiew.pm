package hiew;
require Exporter;

@hiew::ISA = 'Exporter';
@EXPORT = qw/hiew/;

sub hiew(\$){
    my $str = shift;
    my @lines = unpack 'a16'x(length($$str)/16+(length($$str)%16?1:0)), $$str;

    for( 0..$#lines ){
        printf "%08X:  %-17s³ %-17s  %-16s\n", $_*16,
            (map{
                sprintf '%-2s ' x 8, map{
                    sprintf'%02X',$_
                }unpack 'C*', $_
            }unpack 'a8a8', $lines[$_]),
            $lines[$_];
    }
}

1;