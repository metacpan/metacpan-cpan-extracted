use utf8;
use strict;
use warnings;

package DR::Tnt::Dumper;
use base qw(Exporter);
our @EXPORT = qw(pkt_dump dump);
use constant DUMP_LINE_LEN      => 16;
use Data::Dumper;

sub pkt_dump($$) {
    my ($name, $pkt) = @_;

    $name .= sprintf ' (%s octets)', length $pkt;
    my @lines;

    while (DUMP_LINE_LEN < length $pkt) {
        push @lines, substr $pkt, 0, DUMP_LINE_LEN, '';
    }
    push @lines => $pkt if length $pkt;

    for (@lines) {

        $_ = [ $_, $_ ];

        $_->[0] =~ s/(.)/sprintf '%02X ', ord $1/ges;

        while (length($_->[0]) < (3 * DUMP_LINE_LEN)) {
            $_->[0] .= '   ';
        }
        $_->[1] =~ s/(.)/((ord($1) >= 0x20) and (ord($1) <= 0x7F)) ? $1 : '.'/ges;

        $_ = "$_->[0] $_->[1]";
    }
    return join "\n", "request $name", @lines, "";
}

sub dump($) {
    my ($o) = @_; 
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Deepcopy = 1;
    local $Data::Dumper::Maxdepth = 0;
    return Data::Dumper->Dump([$o]);
}

1;


