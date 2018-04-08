use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

use ok 'Crypt::Random::Source::Base::Proc';

{
    my $p = Crypt::Random::Source::Base::Proc->new( command => [qw( echo foo bar )] );

    is( $p->get(3), 'foo', "got data" );

    like exception { $p->get(50) }, qr/enough bytes/, "not having enough data is fatal";
}

done_testing;
# ex: set sw=4 et:
