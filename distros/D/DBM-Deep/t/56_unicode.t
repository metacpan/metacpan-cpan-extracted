use strict;
use warnings FATAL => 'all';

use Test::More;
use t::common qw( new_dbm );
use utf8;

use DBM::Deep;

my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    SKIP: {
       skip "This engine does not support Unicode", 1
         unless $db->supports( 'unicode' );

       my $quote
        = 'Ἐγένετο δὲ λόγῳ μὲν δημοκρατία, λόγῳ δὲ τοῦ πρώτου ἀνδρὸς ἀρχή.'
          .' —Θουκυδίδης';

       $db->{'тэкст'} = $quote;
       is join("-", keys %$db), 'тэкст', 'Unicode keys';
       is $db->{'тэкст'}, $quote, 'Unicode values';

       {
            no warnings 'utf8';
            # extra stress test
            $db->{"\x{d800}"} = "\x{dc00}";
            is join("-", sort keys %$db), "тэкст-\x{d800}",
               'Surrogate keys';
            is $db->{"\x{d800}"}, "\x{dc00}", 'Surrogate values';
       }

       $db->{feen} = "plare\xff";
       $db->{feen} = 'płare';
       is $db->{feen}, 'płare', 'values can be upgraded to Unicode';

    }

}

done_testing;
