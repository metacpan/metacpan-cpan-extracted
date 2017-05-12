# $Id: SSH1.pm,v 1.2 2001/07/11 07:40:09 btrott Exp $

package Crypt::Keys::Public::RSA::SSH1;
use strict;

use Crypt::Keys::Util qw( bitsize );

sub deserialize {
    my $class = shift;
    my %param = @_;
    my($bits, $e, $n) = split /\s+/, $param{Content};
    { e => $e, n => $n };
}

sub serialize {
    my $class = shift;
    my %param = @_;
    my $data = $param{Data};
    join(' ', bitsize($data->{n}), $data->{e}, $data->{n}) . "\n";
}

1;
