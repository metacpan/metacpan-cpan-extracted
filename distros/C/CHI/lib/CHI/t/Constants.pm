package CHI::t::Constants;
$CHI::t::Constants::VERSION = '0.60';
use strict;
use warnings;
use CHI::Test;
use base qw(CHI::Test::Class);

sub test_import : Tests {
    {
        package Foo;
$Foo::VERSION = '0.60';
use CHI::Constants qw(CHI_Meta_Namespace);
    }
    {
        package Bar;
$Bar::VERSION = '0.60';
use CHI::Constants qw(:all);
    }
    {
        package Baz;
$Baz::VERSION = '0.60';
}
    is( Foo::CHI_Meta_Namespace, '_CHI_METACACHE' );
    is( Bar::CHI_Meta_Namespace, '_CHI_METACACHE' );
    ok( Bar->can('CHI_Meta_Namespace') );
    ok( !Baz->can('CHI_Meta_Namespace') );
}

1;
