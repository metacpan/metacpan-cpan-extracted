use warnings;
use strict;
use Test::More;
use File::Path;
use File::Temp('tempdir');

use CloudPAN { persistence_location => tempdir(CLEANUP => 1) };

# unload stolen from Class::Unload. Thanks ilmari!

sub unload {
    no strict 'refs';
    my ($class) = @_;

    # Flush inheritance caches
    @{$class . '::ISA'} = ();

    my $symtab = $class.'::';
    # Delete all symbols except other namespaces
    for my $symbol (keys %$symtab) {
        next if $symbol =~ /\A[^:]+::\z/;
        delete $symtab->{$symbol};
    }
    
    my $inc_file = join( '/', split /(?:'|::)/, $class ) . '.pm';
    delete $INC{ $inc_file };
}


{
    package Foo;
    use
        Acme::Stardate; # Make sure this doesn't show up as a dep
    sub test_me { !!Acme::Stardate::stardate(); }
}

is(Foo::test_me, 1, 'things loaded appropriately');


{
    package Bar;
    BEGIN
    {
        main::unload('Acme::Stardate');
        require
            Acme::Stardate;
    }
    sub test_me { !!Acme::Stardate::stardate(); }
}

is(Foo::test_me, 1, 'things loaded appropriately from cache');

done_testing();

