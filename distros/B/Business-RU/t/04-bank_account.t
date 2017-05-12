use Test::More tests => 16;

use strict;
use warnings;

use_ok( 'Business::RU::BankAccount' );

{
    package MyDecorator;
    use strict;
    use warnings;
    use Moose;

    has 'current_account'       => ( is => 'ro', isa => 'Int' );
    has 'correspondent_account' => ( is => 'ro', isa => 'Int' );
    has 'bic'                   => ( is => 'ro', isa => 'Int' );
    
    with 'Business::RU::BankAccount';

    __PACKAGE__ -> meta() -> make_immutable();
}

#validate_bic()
{
    #positive test
    {
        foreach my $bic ( qw(047654321 047654001 047654002) ) {
            my $object = MyDecorator -> new( bic => $bic );
            ok $object -> validate_bic(), sprintf 'check valid BIC: %s', $bic;
        }
    }

    #negative test
    {
        foreach my $bic ( qw(04765432 147654321 047654010 047654003) ) {
            my $object = MyDecorator -> new( bic => $bic );
            ok !$object -> validate_bic(), sprintf 'check invalid BIC: %s', $bic;
        }
    }
}

#validate_current_account()
{
    #positive test
    {
        my $object = MyDecorator -> new(
            current_account => '40702810300000000649',
            bic             => '044579499',
        );

        ok $object -> validate_bic(), 'check bic';
        ok $object -> validate_current_account(), 'check current account';
    }

    #negative test
    {
        my $object = MyDecorator -> new(
            current_account => '40702810300000000648',
            bic             => '044579499',
        );

        ok $object -> validate_bic(), 'check bic';
        ok !$object -> validate_current_account(), 'check current account';
    }
}

#validate_correspondent_account()
{
    #positive test
    {
        my $object = MyDecorator -> new(
            correspondent_account => '30101810200000000499',
            bic                   => '044579499',
        );

        ok $object -> validate_bic(), 'check bic';
        ok $object -> validate_correspondent_account(), 'check correspondent account';
    }

    #negative test
    {
        my $object = MyDecorator -> new(
            correspondent_account => '30101810200000000483',
            bic                   => '044579499',
        );

        ok $object -> validate_bic(), 'check bic';
        ok !$object -> validate_correspondent_account(), 'check correspondent account';
    }    
}
