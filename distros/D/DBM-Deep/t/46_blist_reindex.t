# This test (and accompanying patch) was submitted by Father Chrysostomos (sprout@cpan.org)

use strict;
use warnings FATAL => 'all';

use Test::More;

use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

{
    my $dbm_factory = new_dbm();
    while ( my $dbm_maker = $dbm_factory->() ) {
        my $db = $dbm_maker->();
    
        ok eval {
            for ( # the checksums of all these begin with ^@:
                qw/ s340l 1970 thronos /,
                "\320\277\320\276\320\262\320\265\320\273\320\265\320\275".
                "\320\275\320\276\320\265", qw/ mr094 despite
                geographically binding bed handmaiden infer lela infranarii
                lxv evtropia recognizes maladies /
            ) {
                $db->{$_} = undef;
            }
            1;
        }, '2 indices can be created at once';
        
        is_deeply [sort keys %$db], [ sort
            qw/ s340l 1970 thronos /,
            "\320\277\320\276\320\262\320\265\320\273\320\265\320\275".
            "\320\275\320\276\320\265", qw/ mr094 despite
            geographically binding bed handmaiden infer lela infranarii
            lxv evtropia recognizes maladies /
        ], 'and the keys were stored correctly';
    }
}

{
    my $dbm_factory = new_dbm();
    while ( my $dbm_maker = $dbm_factory->() ) {
        my $db = $dbm_maker->();
    
        ok eval {
            for ( # the checksums of all these begin with ^@^@^@:
                qw/ dzqtz aqkdqz cxzysd czclmy ktajsi kvlybo kyxowd lvlsda
                    lyzfdi mbethb mcoqeq VMPJC ATZMZZ AXXJDX BXUUFN EIVTII
                    FMOKOI HITVDG JSSJSZ JXQPFK LCVVXW /
            ) {
                $db->{$_} = undef;
            }
            1;
        }, 'multiple nested indices can be created at once';
        
        is_deeply [sort keys %$db], [ sort
            qw/ dzqtz aqkdqz cxzysd czclmy ktajsi kvlybo kyxowd lvlsda
                lyzfdi mbethb mcoqeq VMPJC ATZMZZ AXXJDX BXUUFN EIVTII
                FMOKOI HITVDG JSSJSZ JXQPFK LCVVXW /
        ], 'and the keys were stored correctly';
    }
}

done_testing;
