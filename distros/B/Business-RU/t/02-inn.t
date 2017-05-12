use Test::More tests => 19;

use strict;
use warnings;

use_ok( 'Business::RU::INN' );

{
    package MyDecorator;
    use strict;
    use warnings;
    use Moose;
    has 'inn' => ( 
        is  => 'ro',
        isa => 'Int',
    );
    with 'Business::RU::INN';

    __PACKAGE__ -> meta() -> make_immutable();
}

#validate_inn()
{
    #positive test
    {
        foreach my $inn ( qw(7702581366 7701833652 673002363905 504308599677) ) {
            my $object = MyDecorator -> new( inn => $inn );
            ok $object -> validate_inn(), sprintf 'check valid INN:%s', $inn;
        }
    }

    #negative test
    {
        foreach my $inn ( qw(0 123 123456789 123456789012345 673002363915 504308599670) ) {
            my $object = MyDecorator -> new( inn => $inn );
            ok !$object -> validate_inn(), sprintf 'check invalid INN:%s', $inn;
        }        
    }
}

#is_individual()
{
    {
        my $object = MyDecorator -> new( inn => 7702581366 );
        ok !$object -> is_individual(), 'check individual inn';
        ok $object -> is_company(),     'it is company';
    }

    {
        my $object = MyDecorator -> new( inn => 7702581360 );
        ok !$object -> is_individual(), 'invalid inn';
        ok !$object -> is_company(),    'invalid inn';
    }
}

#is_company()
{
    {
        my $object = MyDecorator -> new( inn => 504308599677 );
        ok $object -> is_individual(), 'it is individual inn';
        ok !$object -> is_company(),   'check company inn';        
    }    

    {
        my $object = MyDecorator -> new( inn => 50430859960 );
        ok !$object -> is_individual(), 'invalid inn';
        ok !$object -> is_company(),   'invalid inn';        
    }    
}
