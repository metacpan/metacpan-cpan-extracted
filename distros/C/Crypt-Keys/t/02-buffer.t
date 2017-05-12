# $Id: 02-buffer.t,v 1.1 2001/07/11 07:52:33 btrott Exp $

use strict;

use Test;
BEGIN { plan tests => 27 }

use Math::Pari;
use Crypt::Keys::Buffer;

my @num = map PARI($_), qw( 34093840983 99999999999999999999 1 );

for my $type (qw( SSH1 SSH2 OpenSSH )) {
    for my $n (@num) {
        my $buffer = Crypt::Keys::Buffer->new( MP => $type );
        ok($buffer);
        ok(exists $buffer->{_get_mp_int} && exists $buffer->{_put_mp_int});
        $buffer->put_mp_int($n);
        ok($buffer->get_mp_int, $n);
    }
}
