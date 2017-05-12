#!/usr/bin/perl

use Test::More tests => 6;
use Test::Exception;
use Test::Deep;
use Data::Dumper;
use lib qw(lib t ../..);

BEGIN {
    use_ok( 'Ambrosia::Meta' ); #test #1
}
require_ok( 'Ambrosia::Meta' ); #test #2

BEGIN {
    use_ok( 'Ambrosia::core::ClassFactory' ); #test #3
}
require_ok( 'Ambrosia::core::ClassFactory' ); #test #4

{
    Ambrosia::core::ClassFactory::create('Employes::Person', {public => [qw/FirstName LastName Age/]});
    my $p = new Employes::Person(FirstName => 'John', LastName => 'Smith', Age => 33);
    cmp_deeply($p->as_hash, {FirstName => 'John', LastName => 'Smith', Age => 33}, 'create is ok'); #test #5
}

{
    my $p = Ambrosia::core::ClassFactory::create_object('Person', (FirstName => 'John', LastName => 'Smith', Age => 33));
    cmp_deeply($p->as_hash, {FirstName => 'John', LastName => 'Smith', Age => 33}, 'create_object is ok'); #test #6
}
