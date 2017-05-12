use Test::More tests => 7;

use strict;
use warnings;

use_ok( 'Business::RU::OKPO' );

{
    package MyDecorator;
    use strict;
    use warnings;
    
    use Moose;
    
    has 'okpo' => (
        is  => 'ro',
        isa => 'Int',
    );
    with 'Business::RU::OKPO';

    __PACKAGE__ -> meta() -> make_immutable();
}

{
    #positive test
    {
        foreach my $okpo ( qw(79011171 7901117001 0154489581) ) {
            my $object = MyDecorator -> new( okpo => $okpo );
            ok $object -> validate_okpo(), sprintf 'check valid OKPO: %s', $okpo;
        }
    }

    #negative test
    {
        foreach my $okpo ( qw(0 1201117124 1901117124) ) {
            my $object = MyDecorator -> new( okpo => $okpo );
            ok !$object -> validate_okpo(), sprintf 'check invalid OKPO: %s', $okpo;
        }
    }    
}