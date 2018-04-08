# ex: set sw=4 et:
use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

use ok 'Crypt::Random::Source::Base::Handle';

{
    my $p = Crypt::Random::Source::Base::Handle->new( handle => \*DATA );

    is( $p->handle, \*DATA, "correct handle set up" );

    is( $p->get(4), "foo\n", "read some bytes" );

    like exception { $p->get(100) }, qr/enough bytes/i, "underread";

    $p->allow_under_read(1);

    my $buf;
    is exception { $buf = $p->get(100) }, undef, "underread now allowed";

    is( $buf, '', "nothing read" );
}

done_testing;

__DATA__
foo
bar
gorch
