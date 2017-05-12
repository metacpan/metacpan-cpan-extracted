use lib 'lib';
use strict;
use warnings;
use Scalar::Util qw(blessed reftype);
use Test::More tests => 21;

use_ok( 'Data::SUID', qw(suid) );

{
    # Set this because Travis CI nodes are known to suffer from buggy
    # Net::Ifconfig::Wrapper
    Data::SUID->_machine_ident(0, 0, 0);
    
    my $machine_ident = Data::SUID->_machine_ident;
    like $machine_ident, qr/\A(?:[0-9a-f][0-9a-f]){3}\z/s;

    my @machine_ident = Data::SUID->_machine_ident;
    is scalar( grep {/\A[0-9]+\z/} @machine_ident ), 3;
    is scalar( grep { $_ >= 0 } @machine_ident ), 3;
    is scalar( grep { $_ <= 255 } @machine_ident ), 3;
}

{
    my $counter = Data::SUID->_count;

    like $counter, qr/\A(?:[0-9a-f]){5}\z/s;
    ok $counter ne Data::SUID->_count;

    $counter = Data::SUID->_reset_count(0xfff00)->_count;
    is $counter, 'fff00';

    while (1)
    {
        $counter = Data::SUID->_count;
        last if hex($counter) == 0;
        last if hex($counter) > 0xFFFFF;    # This should never run or something is really broken. Unlikely to show up on conditional coverage test!
    }

    is hex($counter), 0;
}

{
    my $id = Data::SUID->new();

    is ref($id), 'Data::SUID';
    like $id->hex, qr/\A(?:[0-9a-f][0-9a-f]){12}\z/s;
    is $id->hex, $$id;
    is $id->hex, "$id";
    ok $id->hex eq "$id";
    like $id->base64, qr/\A(?:[A-Za-z0-9\/\+=]){16}\z/s;
    eval { $$id = 'Foo' };
    like $@, qr/Modification of a read-only value attempted/;

    my $new_id = suid();

    is ref($new_id), 'Data::SUID';
    like $new_id->hex, qr/\A(?:[0-9a-f][0-9a-f]){12}\z/s;
    is $new_id->hex, $$new_id;
    ok $new_id->hex eq "$new_id";
    like Data::SUID->hex(), qr/\A(?:[0-9a-f][0-9a-f]){12}\z/s;
    
#    Data::SUID->_reset_count();
#    for ( 1..20000 ) {
#        for my $suid ( Data::SUID->new() ) {
#            diag $suid . ' ' . $suid->dec . ' ' . $suid->uuencode;
#        }
#    }
}
